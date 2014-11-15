_ = require "underscore"
util = require "util"

constructSynsetData = (word) ->
  if word.synsets
    word.synsets = word.synsets.map (s) => new SynsetNode s, word
  else
    word.synsets = null
    
class SynsetNode
  constructor: (synset, word) ->
    @isCandidate = true
    @data = synset
    @wordCount = word.count or 1
    @docCount = 1
    @words = synset.word or []
    @baseWords = word.baseWords.map (bw) => bw.lemma
    if synset.hypernym?.length > 0
    	@parentId = synset.hypernym[0].synsetid
    else
    	@parentId = "root"

module.exports = constructSynsetData
