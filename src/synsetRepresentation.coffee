BPromise = require "bluebird"
_ = require "underscore"
util = require "util"
ProgressBar = require 'progress'
fs = require 'graceful-fs'
require './String.js'
require 'plus_arrays'
{WORDNETIFY_SYNSETS_TREE_HASH_TABLE} = require './Tree'
BinarySearchTree = require 'bin-search-tree'
HashTable = require 'hashtable'
Word             = require './Word'

tm = require "text-miner"
tokenizer = require "sbd"
pos = require "pos"
lexer = new pos.Lexer()
tagger = new pos.Tagger()

WORD_LOOKUP = JSON.parse(fs.readFileSync(__dirname + "/../data/LOOKUP.json"))

for word, synsetidArr of WORD_LOOKUP
  WORD_LOOKUP[word] = synsetidArr.map( (id) ->
    WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(id)
  )

class Vocabulary
  constructor: () ->
    @dict = new HashTable()
  add: (word) ->
    if not @dict.has(word)
      current_length = @dict.length
      @dict.put(word, current_length)
      return current_length
    else
      index = @dict.get(word)
      return index
  getSize: () ->
    return @dict.length
  getArray: () ->
    ret = []
    @dict.forEach( (value, key) ->
      ret[value] = key
    )
    return ret

getCorpusSynsets = (docs) ->
  if Array.isArray(docs) is false then docs = Array(docs)

  progressTagging = new ProgressBar(
    'POS tagging + stopword removal [:bar] :percent :etas',
    { total: docs.length }
  )
  annotated_docs = docs
    .filter( (doc) -> if doc then true else false)
    .map( (doc) -> tokenizer.sentences(doc))
    .map( (doc) ->
      sentences = doc
        .map( (sentence) -> lexer.lex sentence)
        .filter( (sentence) -> sentence isnt null)
        .map( (sentence) ->
          ret = tagger.tag sentence
          return ret
        )
      annotated_doc = sentences.map( (sentence_tokens, index) ->
        return sentence_tokens
          .map( (token) ->
            o = {}
            o.string = token[0]?.toLowerCase()
            o.pos = token[1]
            o.sentence_number = index
            return o
          )
          .filter( (token) ->
            for stop_word in tm.STOPWORDS.EN
              if stop_word == token.string then return false
            return true
          )
          .map( (token) ->
            token.string = token.string.replace(/[^a-z]+/ig, "")
            return token
          )
          .filter( (token) ->
            return token.string != ""
          )
      )
      progressTagging.tick()
      return annotated_doc
    )

  console.log 'Document pre-processing finished'

  progressVocab = new ProgressBar(
    'Create vocabulary [:bar] :percent :etas',
    { total: annotated_docs.length }
  )
  vocab = new Vocabulary()
  wordArrays = annotated_docs.map (sentences) ->
    newSentences = sentences.map (tokens) ->
      res = tokens.reduce (a,b) ->
        existingWord = a.filter (x) -> return x.string == b
        if existingWord.length > 0
          existingWord[0].count++
          return a
        else
          word = {}
          word.string = b.string
          word.pos = b.pos
          word.id = vocab.add b.string
          word.count = 1
          word.sentence_number = b.sentence_number
          return a.concat(word)
      , []
      return res
    progressVocab.tick()
    return newSentences
  return {wordArrays: wordArrays, vocab: vocab}

module.exports = exports = {
  getCorpusSynsets: getCorpusSynsets,
  Word: Word
}
