_ = require 'underscore'

findConditionalProbs = (output, synsetid) ->
  tree = output.tree
  synset1 = tree[synsetid]

  all_relevant_synsets = _.filter(tree, (val, key) ->
    if val.isCandidate == true then true else false
  )

  candidates = []
  for synset2, index in all_relevant_synsets
    common = _.intersection(
      Object.keys(synset2.words),
      Object.keys(synset1.words)
    )
    if common.length == 0
      o = {}
      nCommon = _.intersection(synset1.docs, synset2.docs).length
      nSynset1 = synset1.docs.length
      o.prob = nCommon / nSynset1
      o.synset = synset2.data.words.map( (e) -> e.lemma).splice(0, 3)
      candidates.push(o)

  candidates.sort( (a,b) ->
    if a.prob < b.prob then 1 else (if a.prob > b.prob then -1 else 0)
  )

  return candidates

module.exports = exports = findConditionalProbs
