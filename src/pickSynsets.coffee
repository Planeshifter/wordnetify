_     = require "underscore"
util  = require "util"
require "plus_arrays"
# exectimer = require "exectimer"
jiangConrathSimilarity = require "./jiangConrathSimilarity"
{WORDNETIFY_SYNSETS_TREE_HASH_TABLE} = require "./Tree"

###
Synset disambiguation via function pickSynsets:
@sentence contains all sentence synsets, goal is to pick the synsets as to
maximize the Jiang Conrath similarities between them
###
pickSynsets = (sentence) ->
  # tick = new exectimer.Tick("pickSynsets")
  # tick.start()
  for word, index in sentence
    scores = []
    #console.log "Candidates:"
    for synset in word
      #console.log synset.baseWords.join(",") + "- " +
      WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(synset.synsetid).definition +
       "(ID: " + synset.synsetid + " )"
      similarities = []
      for word2, index2 in sentence
        if index != index2
          dists = word2.map (synset2) -> jiangConrathSimilarity(synset, synset2)
          similarities.push(dists.max())
      synset.score = similarities.sum()
      #console.log "Score: " + synset.score
      scores.push(synset.score)
    maxScore = scores.max()
    chosen = false
    flaggedRemoval = []
    for synset, index in word
      if synset.score != maxScore or chosen == true
        flaggedRemoval.push(index)
      else
        chosen = true
        # console.log "CHOSEN:" + synset.baseWords.join(",") + "- " + WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(synset.synsetid).definition
        # console.log "ID: " + synset.synsetid + " Score:" + synset.score
        # console.log "\n"
    word.splice(i,1) for i in flaggedRemoval by -1
  sentence = sentence.map (synsets) -> synsets[0]
  flaggedRemoval = []
  similarities =  []
  # tick.stop()

  return sentence

module.exports = exports = pickSynsets
