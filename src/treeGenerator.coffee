util = require 'util'
_    = require 'underscore'
{SynsetNode} = require './constructSynsetData'
{WORDNETIFY_SYNSETS_TREE} = require './Tree'
ProgressBar   = require 'progress'
BinarySearchTree = require 'bin-search-tree'

mergeWords = (words1, words2) ->
  ret = _.clone(words1)
  for key, value of words2
    ret[key] = if ret[key] then ret[key] + value else value
  return ret

generateCorpusTree = (docs) =>
  bsTree = new BinarySearchTree((a, b) =>
   if (a < b)
      return -1
   if (a > b)
      return 1
   return 0;
  )

  allSynsets = _.flatten(docs)
  allSynsets = _.groupBy(allSynsets, "synsetid")

  allMergedSynsets = []
  for id, synset of allSynsets
    allMergedSynsets.push synset.reduce( (a,b) =>
      a.docs = a.docs.concat(b.docs)
      a.docCount += b.docCount
      a.words = mergeWords(a.words, b.words)
      return a
    )

  progressCorpusTree = new ProgressBar('Create corpus tree [:bar] :percent :etas', { total: _.size(allMergedSynsets) })
  attachHypernyms = (synset, words, docIndices) =>
    if not bsTree.has(synset.synsetid)
      insert_synset = new SynsetNode synset
      insert_synset.new_words = _.clone(words)
      insert_synset.docs = docIndices
      bsTree.set(synset.synsetid, insert_synset)
    else
      existing_synset = bsTree.get(synset.synsetid)
      existing_synset.new_words = mergeWords(existing_synset.new_words, words)
      existing_synset.docs = _.union(existing_synset.docs, docIndices)
      docIndices = existing_synset.docs
    if synset.hypernym.length > 0 then attachHypernyms(synset.hypernym[0], words, docIndices)
    return

  for synset in allMergedSynsets
    if not bsTree.has(synset.synsetid)
      synset.new_words = _.clone(synset.words)
      bsTree.set(synset.synsetid, synset)
    else
      existing_synset = bsTree.get(synset.synsetid)
      existing_synset.docs =  _.union(existing_synset.docs, synset.docs)
      existing_synset.new_words =  mergeWords(existing_synset.new_words, synset.words)
      existing_synset.baseWords =  existing_synset.baseWords?.concat(synset.baseWords)
    if synset.parentId and synset.parentId != 'root'
      parent = WORDNETIFY_SYNSETS_TREE[synset.parentId]
      attachHypernyms(parent, synset.words, synset.docs)
    progressCorpusTree.tick()

  hashTable = {}
  bsTree.forEach((value, key) =>
    hashTable[key] = value
    hashTable[key].data = WORDNETIFY_SYNSETS_TREE[key]
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
      parent = WORDNETIFY_SYNSETS_TREE[synset.parentId]
      attachHypernyms(parent, synset.words, synset.docs)

  return hashTable

module.exports = {generateCorpusTree: generateCorpusTree, generateWordTree: generateWordTree}
