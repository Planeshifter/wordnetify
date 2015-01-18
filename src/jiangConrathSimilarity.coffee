fs = require 'fs'
_  = require 'underscore'
memoize = require './memoize'

BROWN_JSON = fs.readFileSync(__dirname + '/../data/BROWN.json')
BROWN = JSON.parse(BROWN_JSON);
BROWN_COUNTS = _.countBy(BROWN, (freq) => return freq)

{WORDNETIFY_SYNSETS_TREE} = require './Tree'

getInformation = memoize (nodeId) ->
  freqSum = WORDNETIFY_SYNSETS_TREE[nodeId].tagCount
  N = 130811
  N_r = (count) => BROWN_COUNTS[count] or 0
  prob_hat = ((freqSum + 1) / N) * (N_r(freqSum + 1)/N_r(freqSum))
  return - Math.log(prob_hat)

depth = (node_id) ->
  return WORDNETIFY_SYNSETS_TREE[node_id].ancestorIds.length

getCommonHypernyms = (node1, node2) ->
  return _.intersection(node1.ancestorIds, node2.ancestorIds)

lowestCommonHypernym = (node1, node2) ->
  synsets = getCommonHypernyms(node1, node2);
  depths = synsets.map( (s) => depth(s) )
  max_depth = depths.max()
  return synsets.filter((s) => depth(s) == max_depth)

jiangConrathSimilarity = (node1, node2) ->
  ic1 = getInformation(node1.synsetid)
  ic2 = getInformation(node2.synsetid)
  least_common_subsumer = lowestCommonHypernym(node1, node2)
  ic_lcs = least_common_subsumer ? 0 : getInformation(least_common_subsumer)
  return - ic1 - ic2 + 2 * ic_lcs

module.exports = jiangConrathSimilarity