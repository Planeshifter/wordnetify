_ = require 'underscore'
ProgressBar   = require 'progress'

###
calculates word and document counts for synsets
in the disambiguated @tree.
###
calculateCounts = (tree) ->
  tree_length = _.size(tree)
  progressBarCounting = new ProgressBar(
    'Calculate word counts [:bar] :percent :etas', { total: tree_length }
  )
  for id, synset of tree
    do (synset) ->
      synset.docCount = synset.docs.length
      for key, value of synset.words
        synset.wordCount += value
    progressBarCounting.tick()
  return tree

module.exports = exports = calculateCounts
