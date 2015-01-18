_ = require "underscore"
getSynsets = require "./Word"
morphy = require "./morphy"

pos_adjectives = ["JJ","JJR"]
pos_nouns = ["NN","NNS","NNP","NNPS"]
pos_verbs = ["VB","VBD","VBG","VBN","VBP","VBZ"]

createDocTree = (wordArray) ->
  baseWordArray = wordArray.map( (sentences) =>
    ret = sentences.map( (token) =>
      pos = switch
        when pos_nouns.contains(token.pos) then "n"
        when pos_verbs.contains(token.pos) then "v"
        when pos_adjectives.contains(token.pos) then "a"
        else "none"
      if pos isnt "none" then token.baseWords = morphy token.string, pos else token.baseWords = []
      return token
      )
    return ret;
  )
  synsetsArray = baseWordArray.map (sentences) =>
    ret = sentences.map( (w) =>
      if not _.isEmpty w.baseWords
        pos = switch
          when pos_nouns.contains(w.pos) then "n"
          when pos_verbs.contains(w.pos) then "v"
          when pos_adjectives.contains(w.pos) then "a"
          else "none"
        if pos isnt "none"
          w.synsets = getSynsets(w.baseWords[0].lemma, pos)
        else
          w.synsets = null
        return w
      else
        w.synsets = null
        return w
    )
    return ret
  return synsetsArray

module.exports = createDocTree
