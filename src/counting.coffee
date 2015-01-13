_ = require 'underscore'
ProgressBar   = require 'progress'

calculateCounts = (tree) ->
  tree_length = _.size(tree)
  progressBarCounting = new ProgressBar('Calculate word counts [:bar] :percent :etas', { total: tree_length })
  for id, synset of tree
    do (synset) ->
      synset.docCount = synset.docs.length
      synset.wordCount = synset.words.length
      synset.words =  _.countBy(synset.words)
    progressBarCounting.tick()
  return tree

module.exports = calculateCounts
