_ = require 'underscore'
fs = require 'fs'
util = require 'util'

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


class Tree
  constructor: (obj) ->
    for key, value of obj
      @[key] = value
  depth: (id) ->
    node = @[id]
    ret_depth
    if node.hypernym.length == 0
      ret_depth = 0
    else
      ret_depth = 1 + @depth(node.hypernym[0]?.synsetid)
    return ret_depth
  getAncestorIDs: (node) ->
    debugger
    ret = []
    if (node.hypernym.length > 0)
      ret.push(node.hypernym[0].synsetid)
      ret = ret.concat(@getAncestorIDs(@[node.hypernym[0].synsetid]))
    return ret
  getCommonHypernyms: (node1, node2) ->
    debugger
    node1Hypernyms = @getAncestorIDs(node1)
    node2Hypernyms = @getAncestorIDs(node2)
    return _.intersection(node1Hypernyms, node2Hypernyms)
  lowestCommonHypernym: (node1, node2) ->
    debugger
    synsets = @getCommonHypernyms(node1, node2);
    depths = synsets.map( (s) => @depth(s) )
    max_depth = depths.max()
    return synsets.filter((s) => @depth(s) == max_depth)
  getInformation: (node) ->
    debugger
    freqSum = node.tagCount
    N = 130811
    N_r = (count) => BROWN_COUNTS[count] or 0
    prob_hat = ((freqSum + 1) / N) * (N_r(freqSum + 1)/N_r(freqSum))
    return - Math.log(prob_hat)
  jiangConrathSimilarity: (id1, id2) ->
    node1 = @[id1]
    node2 = @[id2]
    ic1 = @getInformation(node1)
    ic2 = @getInformation(node2)
    least_common_subsumer = @lowestCommonHypernym(node1, node2)
    ic_lcs = least_common_subsumer ? 0 : getInformation(@[least_common_subsumer])
    return - ic1 - ic2 + 2 * ic_lcs

WORDNETIFY_SYNSETS_TREE = new Tree WORDNETIFY_SYNSETS_TREE

module.exports = {WORDNETIFY_SYNSETS_TREE: WORDNETIFY_SYNSETS_TREE, BROWN: BROWN}
