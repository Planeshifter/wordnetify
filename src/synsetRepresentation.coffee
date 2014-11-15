tm = require "text-miner"
BPromise = require "bluebird"
_ = require "underscore"
util = require "util"
logger = require "./logger"
morphy = require "./morphy"
memoize = require "./memoize"
fs = require 'fs'
str = require './String.js'
arr = require './Array.js'

SYNSETS_JSON = fs.readFileSync(__dirname + '/../data/SYNSETS.json')
WORDNETIFY_SYNSETS_TREE = JSON.parse(SYNSETS_JSON)

BROWN_JSON = fs.readFileSync(__dirname + '/../data/BROWN.json')
BROWN = JSON.parse(BROWN_JSON);

BROWN_COUNTS = _.countBy(BROWN, (freq) => return freq)

IdsToHypernyms = (id) -> WORDNETIFY_SYNSETS_TREE[id]

for key, synset of WORDNETIFY_SYNSETS_TREE
    if WORDNETIFY_SYNSETS_TREE.hasOwnProperty(key)
      synset.tagCount = BROWN[key]
      synset.hypernym = synset.hypernym.map IdsToHypernyms

class Word
  constructor: (@lemma, @part_of_speech = null) ->
  getSynsets: (callback) ->
    ret = []
    isContained = (words) =>
      debugger
      return words.some (w) =>
        w.lemma == @lemma

    for key, synset of WORDNETIFY_SYNSETS_TREE
      contained = isContained(synset.words)
      correctPOS = if @part_of_speech then @part_of_speech == synset.pos else true
      if contained is true and correctPOS
        insert_synset = _.clone(synset)
        ret.push(insert_synset)
    return ret

getCorpusSynsets = (docs) ->
    if Array.isArray(docs) is false
      docs = Array(docs)
    corpus = new tm.Corpus(docs)
    corpus = corpus
        .removeInterpunctuation()
        .removeNewlines()
        .toLower()
        .clean()
        .removeWords(tm.STOPWORDS.EN)
        .clean()
    wordArrays = corpus.documents.map (x) => x.split " "
    logger.log "info", "This is the array of word arrays", {wordArrays: wordArrays}
    wordArrays = wordArrays.map (arr) =>
      res = arr.reduce (a,b) =>
        existingWord = a.filter (x) => return x.string == b
        if existingWord.length > 0
          existingWord[0].count++
          return a
        else
          word = {}
          word.string = b
          word.count = 1
          return a.concat(word)
      , []
      return res
    logger.log "info","This is the array of unique word arrays", {uniqueWordArrays: wordArrays}
    res = wordArrays.map (arr) => createDocTree(arr)
    logger.log "info", "These are the doc synset Trees", {docTrees:res}
    return res

createDocTree = (wordArray) ->
  baseWordArray = wordArray.map (x) =>
    console.log(morphy x.string, "n")
    x.baseWords = morphy x.string, "n"
    logger.log "info","Morphy base words", {x:x}
    return x
  synsetsArray = baseWordArray.map (w) =>
    if not _.isEmpty w.baseWords
      bw = new Word w.baseWords[0].lemma, "n"
      w.synsets = getWordSynsets bw
      return w
    else
      w.synsets = null
      return w
  return synsetsArray

getWordSynsets = memoize( (word) => word.getSynsets() )

module.exports = getCorpusSynsets
