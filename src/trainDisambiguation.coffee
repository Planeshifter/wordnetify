{ getCorpusSynsets }            = require "./synsetRepresentation"
createDocTree                   = require "./createDocTree"
util                            = require "util"
{ constructSynsetData }         = require "./constructSynsetData"
readlineSync = require 'readline-sync'
require 'colors'
tm = require "text-miner"
fs = require "fs"
tokenizer = require "sbd"
pos = require "pos"
lexer = new pos.Lexer()
tagger = new pos.Tagger()
require './String.js'
require 'plus_arrays'
_  = require "underscore"
require "plus_arrays"
# exectimer = require "exectimer"
jiangConrathSimilarity = require "./jiangConrathSimilarity"
{WORDNETIFY_SYNSETS_TREE_HASH_TABLE} = require "./Tree"

WORDNETIFY_SYNSETS_TREE = JSON.parse(
  fs.readFileSync __dirname + '/../data/SYNSETS.json'
)
BROWN = JSON.parse(
  fs.readFileSync __dirname + '/../data/BROWN.json'
)

PERFORMANCE = JSON.parse(
  fs.readFileSync __dirname + '/../config/performance.json'
)

###
Synset disambiguation via function pickSynsets:
@sentence contains all sentence synsets, goal is to pick the synsets as to
maximize the Jiang Conrath similarities between them
###
pickSynsets = (sentence, docIndex, sentenceIndex) ->
  # tick = new exectimer.Tick("pickSynsets")
  # tick.start()
  for word, index in sentence
    console.log "DISAMBIGUATION OF SENTENCE: "
    console.log original_docs[docIndex][sentenceIndex].green.bold
    console.log "WORD " + (index+1) + " of " + sentence.length
    console.log word[0].baseWords.join(",")
    scores = []
    console.log "Candidates:"
    for synset, synsetIndex in word
      console.log synsetIndex + "- " +
      WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(synset.synsetid).definition
      similarities = []
      for word2, index2 in sentence
        if index != index2
          dists = word2.map (synset2) -> jiangConrathSimilarity(synset, synset2)
          similarities.push(dists.max())
      synset.score = similarities.sum()
      #console.log "Score: " + synset.score
      scores.push(synset.score)

    maxScore = scores.max()
    chosen = false
    flaggedRemoval = []
    for synset, index in word
      if synset.score != maxScore or chosen == true
        flaggedRemoval.push(index)
      else
        chosen = true
        while true
          console.log('Please enter correct choice:'.grey)
          input_synsetid = readlineSync.question('CHOICE:'.white.inverse + ': ')
          if word[input_synsetid] == undefined
            console.log('Not a valid input.')
          break unless word[input_synsetid] == undefined
        console.log "CHOSEN:" + WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(synset.synsetid).definition
        if (word[input_synsetid].synsetid == synset.synsetid)
          console.log "Correctly disambiguated :)".green
          PERFORMANCE.total += 1
          PERFORMANCE.correct += 1
        else
          console.log "Algorithm picked wrong synset :(".red
          PERFORMANCE.total += 1
          PERFORMANCE.incorrect += 1
        console.log "\n"
  return

disambiguateDoc = (doc, docIndex) ->
  if doc
    for sentence, sentenceIndex in doc
      for word, wordIndex in sentence
        doc[sentenceIndex][wordIndex] = constructSynsetData(word, Number docIndex)

    wordTree = doc.map (sentence) -> sentence.filter ( (word) -> word != null )
    if (wordTree)
      doc = wordTree.map( (sentence, sentenceIndex) ->
        pickSynsets(sentence, docIndex, sentenceIndex)
      )
    else
      doc = null
    return doc
  else
    return null

console.log('Please enter file name of test corpus'.grey)
corpus_file = readlineSync.question('file name:'.white.inverse + ': ')
corpus = JSON.parse(
  fs.readFileSync __dirname + '/../config/' + corpus_file
)


trainDisambiguation = (corpus) ->
  corpus = corpus.remix()

  original_docs = corpus
    .map( (doc) -> tm.utils.expandContractions(doc))
    .map( (doc) ->
      if doc and doc.trim().length > 0
        return tokenizer.sentences(doc)
      else
        return null
    )

  {wordArrays, vocab} = getCorpusSynsets(corpus)

  for doc, index in wordArrays
    ret = createDocTree(doc)
    disambiguateDoc(ret, index)
    console.log('Continue? (y/n):'.grey)
    doContinue = readlineSync.question('CHOICE:'.white.inverse + ': ')
    if doContinue == "n" then break

  console.log "Running total:"
  successRate = (PERFORMANCE.correct/PERFORMANCE.total)*100
  console.log "#{successRate.toFixed(2)}% correctly disambiguated"
  fs.writeFileSync(
    __dirname + '/../config/performance.json',
    JSON.stringify(PERFORMANCE)
  )

module.exports = exports = trainDisambiguation
