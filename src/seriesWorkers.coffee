{ constructSynsetData }         = require "./constructSynsetData"
pickSynsets                     = require "./pickSynsets"

disambiguateDoc = (doc, index) ->

  for sentence, sentenceIndex in doc
    for word, wordIndex in sentence
      doc[sentenceIndex][wordIndex] = constructSynsetData(word, Number index)

  wordTree = doc.map (sentence) -> sentence.filter ( (word) -> word != null )
  if (wordTree)
    doc = wordTree.map( (sentence) -> pickSynsets(sentence) )
  else
    doc = null
  return doc

module.exports = exports = {disambiguateDoc: disambiguateDoc}
