_ = require "underscore"
arr = require "./Array.js"
logger = require "./logger"
fs = require "fs"

pickSynsets = (doc) ->
  for word, index in doc
    scores = []
    for synset in word
      similarities = []
      for word2, index2 in doc
        if index != index2
          dists = word2.map (synset2) => 0
            #tree.jiangConrathSimilarity(synset, synset2)
          similarities.push(dists.max())
      synset.score = similarities.sum()
      scores.push(synset.score)
    maxScore = scores.max()
    logger.log("info","Score Array", {scores: scores, maxScore: maxScore})
    chosen = false
    flaggedRemoval = []
    for synset, index in word
      if synset.score != maxScore or chosen == true
          flaggedRemoval.push(index)
      else
        chosen = true
    word.splice(i,1) for i in flaggedRemoval by -1
  return doc

module.exports = pickSynsets