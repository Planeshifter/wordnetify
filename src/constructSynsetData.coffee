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
    @data =
      { definition:  synset.definition,
      lexdomain: synset.lexdomain,
      pos: synset.pos,
      words: synset.words }
    @wordCount = null
    @docs = if docIndex? then [docIndex] else []
    @docCount = @docs.length

    obj = {}
    if word.id then obj[word.id] = 1
    @words = obj
    
    if (word.baseWords)
      @baseWords = _.unique(word.baseWords.map (bw) => bw.lemma)
    if synset.hypernym?.length > 0
    	@parentId = synset.hypernym[0].synsetid
    else
    	@parentId = "root"

module.exports = {constructSynsetData: constructSynsetData, SynsetNode: SynsetNode}
