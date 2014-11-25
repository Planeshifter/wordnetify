_ = require "underscore"
util = require "util"

constructSynsetData = (word, docIndex) ->
  if word.synsets
    word.synsets = word.synsets.map (s) => new SynsetNode(s, docIndex, word)
  else
    word.synsets = null
  return word.synsets

class SynsetNode
  constructor: (synset, docIndex, word = {}) ->
    @synsetid = synset.synsetid
    @isCandidate = if not _.isEmpty(word) then true else false
    @data = synset
    @wordCount = word.count or 1
    @docs = if docIndex? then [docIndex] else []
    @docCount = 1
    @words = if word.string then Array(word.string) else []
    if (word.baseWords)
      @baseWords = word.baseWords.map (bw) => bw.lemma
    if synset.hypernym?.length > 0
    	@parentId = synset.hypernym[0].synsetid
    else
    	@parentId = "root"

module.exports = {constructSynsetData: constructSynsetData, SynsetNode: SynsetNode}
