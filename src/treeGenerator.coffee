util = require 'util'
_    = require 'underscore'
{SynsetNode} = require './constructSynsetData'
{WORDNETIFY_SYNSETS_TREE_HASH_TABLE} = require './Tree'
ProgressBar   = require 'progress'
HashTable = require 'hashtable'

mergeWords = (words1, words2) ->
  ret = _.clone(words1)
  for key, value of words2
    ret[key] = if ret[key] then ret[key] + value else value
  return ret

generateCorpusTree = (docs) =>
  bsTree = new HashTable()
  allMergedSynsets = new HashTable()

  for doc, docIndex in docs
    for sentence, sentenceIndex in doc
      for synset, synsetIndex in sentence
        # console.log "doc: #{docIndex}; sentence: #{sentenceIndex}; synset: #{synsetIndex}"
        if synset and synset.synsetid
          if not allMergedSynsets.has(synset.synsetid)
            allMergedSynsets.put(synset.synsetid, synset)
          else
            existing_synset = allMergedSynsets.get(synset.synsetid)
            existing_synset.docs = existing_synset.docs.concat(synset.docs)
            existing_synset.docCount += synset.docCount
            existing_synset.words = mergeWords(existing_synset.words, synset.words)

  progressCorpusTree = new ProgressBar('Create corpus tree [:bar] :percent :etas', { total: allMergedSynsets.size() })
  attachHypernyms = (synset, words, docIndices) =>
    if not bsTree.has(synset.synsetid)
      insert_synset = new SynsetNode synset
      insert_synset.new_words = _.clone(words)
      insert_synset.docs = docIndices
      bsTree.put(synset.synsetid, insert_synset)
    else
      existing_synset = bsTree.get(synset.synsetid)
      existing_synset.new_words = mergeWords(existing_synset.new_words, words)
      existing_synset.docs = _.union(existing_synset.docs, docIndices)
      docIndices = existing_synset.docs
    if synset.hypernym.length > 0 then attachHypernyms(synset.hypernym[0], words, docIndices)
    return

  allMergedSynsets.forEach( (key, synset) =>
    if synset.synsetid
      if not bsTree.has(synset.synsetid)
        synset.new_words = _.clone(synset.words)
        bsTree.put(synset.synsetid, synset)
      else
        existing_synset = bsTree.get(synset.synsetid)
        existing_synset.docs =  _.union(existing_synset.docs, synset.docs)
        existing_synset.new_words =  mergeWords(existing_synset.new_words, synset.words)
        existing_synset.baseWords =  existing_synset.baseWords?.concat(synset.baseWords)
      if synset.parentId and synset.parentId != 'root'
        parent = WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(synset.parentId)
        attachHypernyms(parent, synset.words, synset.docs)
      progressCorpusTree.tick()
  )

  hashTable = {}
  bsTree.forEach((key, value) =>
    hashTable[key] = value
    hashTable[key].data = WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(key)
    delete hashTable[key].data.hypernym
    delete hashTable[key].tagCount
    delete hashTable[key].score
    delete hashTable[key].ancestorIds
    delete hashTable[key].words
    hashTable[key].words = hashTable[key].new_words
    delete hashTable[key].new_words
  )
  return hashTable

generateWordTree = (doc) =>
  hashTable = {}

  attachHypernyms = (synset, words, docIndices) =>
    id = synset.synsetid
    if id not of hashTable
      hashTable[id] = new SynsetNode synset
      hashTable[id].words = words
      hashTable[id].docs = docIndices
    else
      hashTable[id].words = hashTable[id].words?.concat(words)
      hashTable[id].docs = _.union(hashTable[id].docs, docIndices)

    if synset.hypernym.length > 0 then attachHypernyms(synset.hypernym[0], words, hashTable[id].docs)
    return

  for synset in doc
    if synset.synsetid not of hashTable
      hashTable[synset.synsetid] = synset
    else
      existing_synset = hashTable[synset.synsetid]
      existing_synset.docs =  _.union(existing_synset.docs, synset.docs)
      existing_synset.words =  existing_synset.words?.concat(synset.words)
      existing_synset.baseWords =  existing_synset.baseWords?.concat(synset.baseWords)
    if synset.parentId and synset.parentId != 'root'
      parent = WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(synset.parentId)
      attachHypernyms(parent, synset.words, synset.docs)

  return hashTable

module.exports = {generateCorpusTree: generateCorpusTree, generateWordTree: generateWordTree}
