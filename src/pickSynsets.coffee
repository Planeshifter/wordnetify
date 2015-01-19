_ = require "underscore"
require "plus_arrays"
# exectimer = require "exectimer"
jiangConrathSimilarity = require "./jiangConrathSimilarity"

pickSynsets = (sentence) ->
  # tick = new exectimer.Tick("pickSynsets")
  # tick.start()
  for word, index in sentence
    scores = []
    for synset in word
      similarities = []
      for word2, index2 in sentence
        if index != index2
          dists = word2.map (synset2) => jiangConrathSimilarity(synset, synset2)
          similarities.push(dists.max())
      synset.score = similarities.sum()
      scores.push(synset.score)
    maxScore = scores.max()
    chosen = false
    flaggedRemoval = []
    for synset, index in word
      if synset.score != maxScore or chosen == true
          flaggedRemoval.push(index)
      else
        chosen = true
    word.splice(i,1) for i in flaggedRemoval by -1
  sentence = sentence.map (synsets) => synsets[0]
  flaggedRemoval = []
  similarities =  []
  # tick.stop()
  return sentence

module.exports = pickSynsets
