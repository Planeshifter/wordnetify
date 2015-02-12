fs = require 'fs'
_  = require 'underscore'
memoize = require './memoize'
HashTable = require 'hashtable'

###
synset counts tagged on the Brown corpus, used
as relative frequencies in calculation of synset
information
###
BROWN = JSON.parse( fs.readFileSync __dirname + '/../data/BROWN.json' )
BROWN_COUNTS = _.countBy(BROWN, (freq) -> return freq)

BROWN_COUNTS_HASH_TABLE = new HashTable()
for key, value of BROWN_COUNTS
  BROWN_COUNTS_HASH_TABLE.put(key, value)
BROWN_COUNTS = {}

{WORDNETIFY_SYNSETS_TREE_HASH_TABLE} = require './Tree'

###
returns the estimated information for synset with id *nodeid*
###
getInformation = memoize (nodeId) ->
  freqSum = WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(nodeId).tagCount
  N = 130811
  N_r = (count) -> BROWN_COUNTS_HASH_TABLE.get(count) or 1
  prob_hat = ((freqSum + 1) / N) * (N_r(freqSum + 1)/N_r(freqSum))
  ret = - Math.log(prob_hat)
  return ret

###
depth of synset with id *node_id*, defined as the number of nodes
up to the root node, i.e. the number of ancestors
###
depth = (node_id) ->
  return WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(node_id).ancestorIds.length

###
returns the ids of all synsets which are hypernymsof both node1 and node2
###
getCommonHypernyms = (node1, node2) ->
  return _.intersection(node1.ancestorIds, node2.ancestorIds)

###
find lowest common subsumer for nodes *node1* and *node2*,
used in calculation of the Jiang & Conrath similarity measure
###
lowestCommonHypernym = (node1, node2) ->
  synsets = getCommonHypernyms(node1, node2)
  depths = synsets.map( (s) -> depth(s) )
  max_depth = depths.max()
  return synsets.filter((s) -> depth(s) == max_depth)

###
calculates Jiang & Conrath Similarity measure of two synsets.
Considers the information content of
lowest common subsumer (lcs) and the two compared concepts
to calculate the distance between the two concepts.
Source: http://arxiv.org/pdf/cmp-lg/9709008.pdf
###
jiangConrathSimilarity =  (node1, node2) ->
  ic1 = getInformation(node1.synsetid)
  ic2 = getInformation(node2.synsetid)
  # console.log "IC1: " + ic1
  # console.log "IC2: " + ic2
  least_common_subsumer = lowestCommonHypernym(node1, node2)
  #if least_common_subsumer.length > 0
  #  console.log "LCS: " + WORDNETIFY_SYNSETS_TREE_HASH_TABLE.get(least_common_subsumer[0]).synsetid
  ic_lcs = if least_common_subsumer.length > 0 then getInformation(least_common_subsumer[0]) else 0
  # console.log "IC_LCS: " + ic_lcs
  return - ic1 - ic2 + 2 * ic_lcs

module.exports = exports = jiangConrathSimilarity
