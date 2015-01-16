tm = require "text-miner"
nlp = require "nlp_compromise"
BPromise = require "bluebird"
_ = require "underscore"
util = require "util"
ProgressBar = require 'progress'
memoize = require "./memoize"
fs = require 'graceful-fs'
str = require './String.js'
require 'plus_arrays'
{WORDNETIFY_SYNSETS_TREE} = require './Tree'

WORD_LOOKUP = JSON.parse(fs.readFileSync(__dirname + "/../data/LOOKUP.json"))

for word, synsetidArr of WORD_LOOKUP
  WORD_LOOKUP[word] = synsetidArr.map( (id) => WORDNETIFY_SYNSETS_TREE[id] )

class Vocabulary
  constructor: () ->
    @dict = []
  add: (word) ->
    index = @dict.indexOf(word)
    if index is -1
      current_length = @dict.length
      @dict[current_length] = word
      return current_length
    else return index
  getSize: () ->
    return @dict.size
  getArray: () ->
    return @dict

class Word
  constructor: (@lemma, @part_of_speech = null) ->
  getSynsets: (callback) ->
    ret = if WORD_LOOKUP[@lemma] then WORD_LOOKUP[@lemma] else []
    ret = ret
      .filter( (synset) => if @part_of_speech then synset.pos == @part_of_speech else true)
    return ret

DICTIONARY = JSON.parse(fs.readFileSync(__dirname + "/../data/DICTIONARY.json"))
EXCEPTIONS = JSON.parse(fs.readFileSync(__dirname + "/../data/EXCEPTIONS.json"))

MORPHY_SUBSTITUTIONS = {
  NOUN: [{ suffix: 's', ending: ''},
  { suffix: 'ses', ending: 's'},
  { suffix: 'ves', ending: 'f'},
  { suffix: 'xes', ending: 'x'},
  { suffix: 'zes', ending: 'z'},
  { suffix: 'ches', ending: 'ch'},
  { suffix: 'shes', ending: 'sh'},
  { suffix: 'men', ending: 'man'},
  { suffix: 'ies', ending: 'y'}],
  VERB: [{ suffix: 's', ending: ''},
  { suffix: 'ies', ending: 'y'},
  { suffix: 'es', ending: 'e'},
  { suffix: 'es', ending: ''},
  { suffix: 'ed', ending: 'e'},
  { suffix: 'ed', ending: ''},
  { suffix: 'ing', ending: 'e'},
  { suffix: 'ing', ending: ''}],
  ADJECTIVE: [{ suffix: 'er', ending: ''},
  { suffix: 'est', ending: ''},
  { suffix: 'er', ending: 'e'},
  { suffix: 'est', ending: 'e'}]
}

morphy = (input_str, pos) ->
  debugger
  rulesOfDetachment = (word, substitutions) =>
    result = []
    DICTIONARY.filter((elem) =>
      elem.lemma is word
    ).forEach (elem) =>
      if elem.pos is pos
        obj = new Word(elem.lemma)
        obj.part_of_speech = elem.pos
        result.push obj

    i = 0
    while i < substitutions.length
      suffix = substitutions[i].suffix
      new_ending = substitutions[i].ending
      if word.endsWith(suffix) is true
        new_word = word.substring(0, word.length - suffix.length) + new_ending
        substitutions.splice i, 1
        if new_word.endsWith("e") and not word.endsWith("e")
          substitutions.push
            suffix: "e"
            ending: ""

        recResult = rulesOfDetachment(new_word, substitutions)
        (if Array.isArray(recResult) then result = result.concat(recResult) else result.push(recResult))
      i++
    result
  unless pos
    arr = [ "n", "v", "a", "r", "s" ]
    resArray = []
    i = 0
    while i <= 4
      resArray.push morphy(input_str, arr[i])
      i++
    reducedArray = []
    q = 0
    while q < resArray.length
      current = resArray[q]
      reducedArray.push current
      q++
    return _.flatten(reducedArray)
  substitutions = undefined
  switch pos
    when "n"
      substitutions = _.clone(MORPHY_SUBSTITUTIONS.NOUN)
    when "v"
      substitutions = _.clone(MORPHY_SUBSTITUTIONS.VERB)
    when "a"
      substitutions = _.clone(MORPHY_SUBSTITUTIONS.ADJECTIVE)
    else
      substitutions = []
  found_exceptions = []
  exception_morphs = EXCEPTIONS.map((elem) ->
    elem.morph
  )
  index = exception_morphs.indexOf(input_str)
  while index isnt -1
    if EXCEPTIONS[index].pos is pos
      base_word = new Word(EXCEPTIONS[index].lemma)
      base_word.part_of_speech = pos
      found_exceptions.push base_word
    index = exception_morphs.indexOf(input_str, index + 1)
  if found_exceptions.length > 0
    found_exceptions
  else
    if pos is "n" and input_str.endsWith("ful")
      suffix = "ful"
      input_str = input_str.slice(0, input_str.length - suffix.length)
    else
      suffix = ""
    rulesOfDetachment input_str, substitutions

getCorpusSynsets = (docs) ->
    if Array.isArray(docs) is false
      docs = Array(docs)

    annotated_docs = docs.map( (doc) => nlp.pos(doc))
    annotated_docs = annotated_docs.map( (doc) =>
      sentences = doc.sentences.map( (sentence) => sentence.tokens)
      annotated_doc = sentences.map( (sentence_tokens, index) =>
        return sentence_tokens.map( (token) =>
          o = {}
          o.string = token.normalised
          o.pos = token.pos.parent
          o.sentence_number = index
          return o
        ).filter( (token) =>
          for stop_word in tm.STOPWORDS.EN
            if stop_word == token.string then return false
          return true
        )
      )
      return annotated_doc
    )

    console.log 'Document pre-processing finished'
    vocab = new Vocabulary()
    wordArrays = annotated_docs.map (sentences) =>
      newSentences = sentences.map (tokens) =>
        res = tokens.reduce (a,b) =>
          existingWord = a.filter (x) => return x.string == b
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
      return newSentences
    return {wordArrays: wordArrays, vocab: vocab}

createDocTree = (wordArray) ->
  baseWordArray = wordArray.map( (sentences) =>
    ret = sentences.map( (token) =>
      pos = switch token.pos
        when "noun" then "n"
        when "verb" then "v"
        when "adjective" then "a"
        else "none"
      if pos isnt "none" then token.baseWords = morphy token.string, pos else token.baseWords = []
      return token
      )
    return ret;
  )
  synsetsArray = baseWordArray.map (sentences) =>
    ret = sentences.map( (w) =>
      if not _.isEmpty w.baseWords
        pos = switch w.pos
          when "noun" then "n"
          when "verb" then "v"
          when "adjective" then "a"
          else "none"
        if pos isnt "none"
          bw = new Word w.baseWords[0].lemma, pos
          w.synsets = getWordSynsets bw
        else
          w.synsets = null
        return w
      else
        w.synsets = null
        return w
    )
    console.log ret
    return ret
  return synsetsArray

getWordSynsets = memoize( (word) => word.getSynsets() )

module.exports = exports = {
  createDocTree: createDocTree
  getCorpusSynsets: getCorpusSynsets,
  Word: Word
}
