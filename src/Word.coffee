fs = require 'fs'
WORD_LOOKUP = JSON.parse(fs.readFileSync(__dirname + "/../data/LOOKUP.json"))
{WORDNETIFY_SYNSETS_TREE} = require './Tree'

for word, synsetidArr of WORD_LOOKUP
  WORD_LOOKUP[word] = synsetidArr.map( (id) => WORDNETIFY_SYNSETS_TREE[id] )

class Word
  constructor: (@lemma, @part_of_speech = null) ->
  getSynsets: (callback) ->
    ret = if WORD_LOOKUP[@lemma] then WORD_LOOKUP[@lemma] else []
    if @part_of_speech then ret = ret.filter( (synset) => synset.pos == @part_of_speech)
    return ret

module.exports = Word
