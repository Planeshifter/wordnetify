util = require 'util'
fs = require 'fs'
_ = require 'underscore'
require 'plus_arrays'
ProgressBar   = require 'progress'


###
returns all possible n choose 2 pairs from input array @arr
###
pairs = (arr) ->
  res = []
  l = arr.length
  i = 0
  while i < l
    j = i + 1
    while j < l
      res.push [
        arr[i]
        arr[j]
      ]
      ++j
    ++i
  return res

calculateFreqTable = (synset1, synset2, nDocs) ->
  # X: Synset1, Y: Synset2
  nCommon = _.intersection(synset1.docs, synset2.docs).length
  nOnlyX = synset1.docs.length - nCommon
  nOnlyY = synset2.docs.length - nCommon
  nNone    = nDocs - nOnlyX - nOnlyY + nCommon

  ###
  Estimated probabilities:
  X\Y  0            1
  0  nNone/nDocs   nOnlyY/nDocs
  1  nOnlyX/nDocs  nCommon/nDocs
  ###
  xy_prob = [
    [nNone/nDocs, nOnlyY/nDocs],
    [nOnlyX/nDocs, nCommon/nDocs]
  ]
  x_prob = [
    (nDocs - synset1.docs.length) / nDocs,
    synset1.docs.length / nDocs
  ]
  y_prob = [
    (nDocs - synset2.docs.length) / nDocs,
    synset2.docs.length / nDocs
  ]
  return {
    x: x_prob,
    y: y_prob,
    xy: xy_prob
  }
###
calculate the mutual information between the two supplied synsets, defined as
∑x ∑y log(p(x,y) / p(x) p(y)) p(x,y)
###
calculateMutualInformation = (synset1, synset2, nDocs) ->
  probs = calculateFreqTable(synset1, synset2, nDocs)
  mutualInfo = 0
  for i in [0,1]
    for j in [0,1]
      mutualInfo += probs.xy[i][j] *
        (Math.log(Math.max(probs.xy[i][j], 0.0001) / (probs.x[i] * probs.y[j])))
  return mutualInfo

calculatePhi = (synset1, synset2, nDocs) ->
  probs = calculateFreqTable(synset1, synset2, nDocs)
  phi = ((probs.xy[1][1] * probs.xy[0][0])-(probs.xy[1][0] * probs.xy[0][1])) /
    ( Math.sqrt( probs.x[0] * probs.x[1] * probs.y[0] * probs.y[1] ) )
  return phi

###
given wordnetify @output and @synsetid, finds the mutual information
with all other synsets with which it does not share corpus words, i.e. which
are in no ancestral relationship to the synset with id @synsetid
###
findCorrelatedSynsetsWithId = (output, synsetid) ->
  tree = output.tree
  nDocs = output.corpus.length
  nSynsets = Object.keys(output.tree).length
  synset1 = tree[synsetid]

  all_relevant_synsets = _.filter(tree, (val, key) ->
    if val.isCandidate == true then true else false
  )

  candidates = []
  progressCorrelation = new ProgressBar(
    'Calculate correlations [:bar] :percent :etas',
    { total: all_relevant_synsets.length }
  )
  for synset2, index in all_relevant_synsets
    common = _.intersection(
      Object.keys(synset2.words),
      Object.keys(synset1.words)
    )
    if synset2.docs.containsAny(synset1.docs) and common.length == 0
      o = {}
      o.mutualInfo = calculateMutualInformation(synset1, synset2, nDocs)
      o.phi = calculatePhi(synset1, synset2, nDocs)
      o.synset2 = synset2.data.words.map( (e) -> e.lemma).splice(0, 3)
      o.synset2id = synset2.synsetid
      o.synset2ancestorIds = synset2.data.ancestorIds
      candidates.push(o)
    progressCorrelation.tick()

  console.log "#{candidates.length} relevant correlated synsets identified"
  return candidates

###
for wordnetify output object, finds all pairwise-correlated synsets
and returns those with largest mutual information
###
findCorrelatedSynsets = (output) ->
  tree = output.tree
  nDocs = output.corpus.length
  nSynsets = Object.keys(output.tree).length

  all_relevant_keys = _.filter(tree, (val, key) ->
    if val.isCandidate == true then true else false
  )
  all_pairs = pairs(all_relevant_keys)
  progressCorrelation = new ProgressBar(
    'Calculate correlations [:bar] :percent :etas', { total: all_pairs.length }
  )
  candidates = []
  maxMutualInfo = []
  for pair, index in all_pairs
    synset1 = pair[0]
    synset2 = pair[1]
    common = _.intersection(
      Object.keys(synset2.words), Object.keys(synset1.words)
    )
    if synset2.docs.containsAny(synset1.docs) and common.length == 0
      o = {}
      mi = calculateMutualInformation(synset1, synset2, nDocs)
      maxMutualInfo.push(mi)
      if (mi > maxMutualInfo.mean() * 2)
        o.mutualInfo = mi
        o.synset1 = synset1.data.words.map( (e) -> e.lemma ).splice(0, 3)
        o.synset2 = synset2.data.words.map( (e) -> e.lemma ).splice(0, 3)
        candidates.push(o)
    progressCorrelation.tick()

  console.log "#{candidates.length} relevant synset pairs identified"
  return _.sortBy(candidates, (o) -> o.mutualInfo).reverse()

module.exports = exports = {
  findCorrelatedSynsets: findCorrelatedSynsets,
  findCorrelatedSynsetsWithId: findCorrelatedSynsetsWithId
}
