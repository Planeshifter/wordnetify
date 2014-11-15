_ = require 'underscore'

class Tree
  constructor: () ->
  depth: (id) ->
    node = @[id]
    ret_depth
    if not node.hypernym
      ret_depth = 0
    else
      ret_depth = 1 + @depth(node.parentId)
    return ret_depth
  getAncestorIDs: (node) ->
    ret = []
    if (node.hypernyn)
      ret.push(node.parentId)
      ret = ret.concat(@getAncestorIDs(@[node.parentId]))
    return ret
  getCommonHypernyms: (node1, node2) ->
    node1Hypernyms = @getAncestorIDs(node1)
    node2Hypernyms = @getAncestorIDs(node2)
    return _.intersection(node1Hypernyms, node2Hypernyms)
  lowestCommonHypernym: (node1, node2) ->
    synsets = @getCommonHypernyms(node1, node2);
    depths = synsets.map( (s) => @depth(s) )
    max_depth = depths.max()
    return synsets.filter((s) => self.depth(s) == max_depth)
  getInformation: (node) ->
    freqSum = node.tagCount
    N = 130811;
    N_r = (count) => BROWN_COUNTS[count] or 0
    prob_hat = ((freqSum + 1) / N) * (N_r(freqSum + 1)/N_r(freqSum))
    return - Math.log(prob_hat)
  jiangConrathSimilarity: (node1, node2) ->
    ic1 = getInformation(node1)
    ic2 = getInformation(node2)
    least_common_subsumer = @lowestCommonHypernym(node1, node2)
    ic_lcs = least_common_subsumer ? 0 : getInformation(self[least_common_subsumer])
    return - ic1 - ic2 + 2 * ic_lcs

module.exports = Tree
