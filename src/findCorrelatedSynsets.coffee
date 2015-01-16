util = require 'util'
fs = require 'fs'
_ = require 'underscore'
require 'plus_arrays'

findCorrelatedWithID = (output, synsetid) ->
  tree = output.tree
  synset_docs = tree[synsetid].docs
  synset_words = Object.keys(tree[synsetid].words)

  console.log(synset_words)

  for key, synset2 of tree
    if not synset2.docs.containsAny(synset_docs)
       delete tree[key]
    if  _.intersection(Object.keys(synset2.words), synset_words).length > 0
      delete tree[key]
    else
      tree[key].docs = _.intersection(synset_docs, synset2.docs)
      tree[key].docCount =   tree[key].docs.length
      tree[key].wordCount =  tree[key].docCount
    if synset2.isCandidate == false
      delete tree[key]

  synsetList = _.map(tree, (e) =>
    o = {}
    o.words = e.data.words.map((e)=>e.lemma).splice(0,3)
    o.definition = e.data.definition
    o.docCount = e.docCount
    return o
  )
  return synsetList

module.exports = findCorrelatedWithID
