util = require 'util'
_    = require 'underscore'
{SynsetNode} = require './constructSynsetData'
{WORDNETIFY_SYNSETS_TREE} = require './Tree'
ProgressBar   = require 'progress'
BinarySearchTree = require 'bin-search-tree'

generateCorpusTree = (docs) =>
  bsTree = new BinarySearchTree((a, b) =>
   if (a < b)
      return -1
   if (a > b)
      return 1
   return 0;
  )
  allSynsets = _.flatten(docs)

  progressCorpusTree = new ProgressBar('Create corpus tree [:bar] :percent', { total: _.size(allSynsets) })
  attachHypernyms = (synset, words, docIndices) =>
    if not bsTree.has(synset.synsetid)
      insert_synset = new SynsetNode synset
      insert_synset.words = words
      insert_synset.docs = docIndices
      bsTree.set(synset.synsetid, insert_synset)
    else
      existing_synset = bsTree.get(synset.synsetid)
      existing_synset.words = existing_synset.words.concat(words)
      existing_synset.docs = _.union(existing_synset.docs, docIndices)
      docIndices = existing_synset.docs
    if synset.hypernym.length > 0 then attachHypernyms(synset.hypernym[0], words, docIndices)
    return

  for synset in allSynsets
    if not bsTree.has(synset.synsetid)
      bsTree.set(synset.synsetid, synset)
    else
      existing_synset = bsTree.get(synset.synsetid)
      existing_synset.docs =  _.union(existing_synset.docs, synset.docs)
      existing_synset.words =  existing_synset.words?.concat(synset.words)
      existing_synset.baseWords =  existing_synset.baseWords?.concat(synset.baseWords)
    if synset.parentId and synset.parentId != 'root'
      parent = WORDNETIFY_SYNSETS_TREE[synset.parentId]
      attachHypernyms(parent, synset.words, synset.docs)
    progressCorpusTree.tick()

  hashTable = {}
  bsTree.forEach((value, key) =>
    hashTable[key] = value
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
