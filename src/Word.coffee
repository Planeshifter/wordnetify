fs = require 'fs'
WORD_LOOKUP = JSON.parse(fs.readFileSync( __dirname + "/../data/LOOKUP.json") )
{WORDNETIFY_SYNSETS_TREE_HASH_TABLE} = require './Tree'
config = JSON.parse( fs.readFileSync( __dirname + "/../config/config.json" ) )

for word, synsetidArr of WORD_LOOKUP
  WORD_LOOKUP[word] = synsetidArr.map( (id) ->
    WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(id)
  )

###
Word class with attributes
  @lemma: the base word string from Morphy
  @part_of_speech: the determined tag, default null
method @getSynsetIds returns all synset ids of the candidate
set of the word
###
class Word
  constructor: (@lemma, @part_of_speech = null) ->
  getSynsets: (callback) ->
    ret = if WORD_LOOKUP[@lemma] then WORD_LOOKUP[@lemma] else []
    if @part_of_speech
      ret = ret.filter( (synset) =>
        synset.pos == @part_of_speech
      ).filter( (synset) ->
        config.blacklist.contains(synset.synsetid)
      )
    return ret
  getSynsetIds: (callback) ->
    ret = if WORD_LOOKUP[@lemma] then WORD_LOOKUP[@lemma] else []
    if @part_of_speech then ret = ret.filter( (synset) =>
      synset.pos == @part_of_speech
    )
    return ret
      .map( (synset) -> synset.synsetid)
      .filter( (synset) -> config.blacklist.contains(synset) is false)

###
given lemma obtained from Morphy and part of speech tag,
we retrieve all synset ids of the candidate set
###
getSynsetIds = (lemma, part_of_speech) ->
  ret = if WORD_LOOKUP[lemma] then WORD_LOOKUP[lemma] else []
  if part_of_speech then ret = ret.filter( (synset) ->
    synset.pos == part_of_speech
  )
  console.log config.blacklist
  return ret.map( (synset) -> synset.synsetid)
      .filter( (synset) -> config.blacklist.contains(synset) is false)

module.exports = exports = {Word: Word, getSynsetIds: getSynsetIds}
