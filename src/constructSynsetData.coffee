_ = require "underscore"
util = require "util"
{WORDNETIFY_SYNSETS_TREE_HASH_TABLE} = require './Tree'

constructSynsetData = (word, docIndex) ->
  if word.synsets
    word.synsets = word.synsets.map (id) -> new SynsetNode(
      WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(id),
      docIndex,
      word
    )
  else
    word.synsets = null
  return word.synsets

class SynsetNode
  constructor: (synset, docIndex, word = {}) ->
    @synsetid = synset.synsetid
    @isCandidate = if not _.isEmpty(word) then true else false
    @data = null
    @wordCount = null
    @docs = if docIndex? then [docIndex] else []
    @docCount = @docs.length
    @tagCount = synset.tagCount
    @ancestorIds = synset.ancestorIds

    obj = Object.create(null)
    if word.id != undefined then obj[word.id] = word.count
    @words = obj

    if (word.baseWords)
      @baseWords = _.unique(word.baseWords.map (bw) -> bw.lemma)

    @parentId = if synset.hypernym?.length > 0 then synset.hypernym[0].synsetid else "root"

module.exports = exports = {
  constructSynsetData: constructSynsetData,
  SynsetNode: SynsetNode
}
