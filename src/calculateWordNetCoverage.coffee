tokenizer = require "sbd"
fs        = require "fs"
tm        = require "text-miner"
_         = require "underscore"

pos = require "pos"
lexer = new pos.Lexer()
tagger = new pos.Tagger()

calculateCoverage = (file, options) ->
  file = JSON.parse( fs.readFileSync(file) )
  {tree, vocab, corpus} = file
  nWords = vocab.length

  words = []
  nTotalWordsInWordNet = 0
  for id, synset of tree
    words = words.concat( Object.keys(synset.words) )
    if synset.parentId == "root"
      nTotalWordsInWordNet += _.map(synset.words).reduce( (a,b) -> a + b )

  nWordsInWordNet = _.uniq(words).length
  console.log "Vocabulary Size: #{nWords}"
  console.log "Included in WordNet: #{nWordsInWordNet}"
  console.log "Coverage of Vocabulary: #{nWordsInWordNet / nWords}"

  nTotalWords = 0

  corpus = corpus
    .map( (doc) -> tm.utils.expandContractions(doc) )
    .map( (doc) ->
      if doc and doc.trim().length > 0
        return tokenizer.sentences(doc)
      else
        return null
    )
    .forEach( (doc, id) ->
      if doc
        sentences = doc
          .map( (sentence) -> if sentence then lexer.lex sentence else null)
          .filter( (sentence) -> sentence isnt null)
          .map( (sentence) ->
            ret = tagger.tag sentence
            return ret
          )
        annotated_doc = sentences.map( (sentence_tokens, index) ->
          return sentence_tokens
            .map( (token) -> token[0]?.toLowerCase() )
            .filter( (token) ->
              for stop_word in tm.STOPWORDS.EN
                if stop_word == token then return false
              return true
            )
            .map( (token) -> token.replace(/[^a-z]+/ig, "") )
            .filter( (token) -> token.string != "" )
            .forEach( (token) ->
              if token then nTotalWords += 1
            )
        )
    )
  console.log("nTotalWords: #{nTotalWords}")
  console.log("in WordNet: #{nTotalWordsInWordNet}")
  console.log("Total Coverage: #{nTotalWordsInWordNet / nTotalWords}")



module.exports = calculateCoverage
