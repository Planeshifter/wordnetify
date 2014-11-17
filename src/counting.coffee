_ = require 'underscore'

calculateCounts = (tree) ->
  for id, synset of tree
    do (synset) ->
      synset.docCount = synset.docs.length
      synset.wordCount = synset.words.length
      synset.words =  _.countBy(synset.words)
  return tree

module.exports = calculateCounts
