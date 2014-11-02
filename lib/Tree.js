var _ = require('underscore');

function Tree(){

}

function depth(id){
  var self = this;
  var node = self[id];
  var ret_depth;
  if (node.parentId == "root"){
    ret_depth = 0;
  } else {
    ret_depth = 1 + self.depth(node.parentId);
  }
  return ret_depth;
}

function getAncestorIDs(node){
  var self = this;
  var ret = [];
  if (node.parentId !== "root"){
    ret.push(node.parentId);
    ret = ret.concat(self.getAncestorIDs(self[node.parentId]));
  }
  return ret;
}

function getCommonHypernyms(node1, node2){
  var node1Hypernyms = this.getAncestorIDs(node1);
  var node2Hypernyms = this.getAncestorIDs(node2);

  return _.intersection(node1Hypernyms, node2Hypernyms);
}

function lowestCommonHypernym(node1, node2){
  var self = this;
  var synsets = self.getCommonHypernyms(node1, node2);
  var depths = synsets.map(function(s){
    return self.depth(s);
  });
  var max_depth = depths.max();
  return synsets.filter(function(s){
    return self.depth(s) === max_depth;
  });
}

function getInformation(node){
  var freqSum = node.tagCount;
  var N = 130811;
  var N_r = function(count){
    return BROWN_COUNTS[count] || 0;
  };
  var prob_hat = ((freqSum + 1) / N) * (N_r(freqSum + 1)/N_r(freqSum));
  return - Math.log(prob_hat);
}

function jiangConrathSimilarity(node1, node2){
  var self = this;
  var ic1 = getInformation(node1);
  var ic2 = getInformation(node2);
  var least_common_subsumer = self.lowestCommonHypernym(node1, node2);
  var ic_lcs = least_common_subsumer ? 0 : getInformation(self[least_common_subsumer]);
  return - ic1 - ic2 + 2 * ic_lcs;
}

Object.defineProperty(Tree.prototype, "depth", {
  enumerable: false,
  value: depth
});

Object.defineProperty(Tree.prototype, "getAncestorIDs", {
  enumerable: false,
  value: getAncestorIDs
});

Object.defineProperty(Tree.prototype, "getCommonHypernyms", {
  enumerable: false,
  value: getCommonHypernyms
});

Object.defineProperty(Tree.prototype, "lowestCommonHypernym", {
  enumerable: false,
  value: lowestCommonHypernym
});

Object.defineProperty(Tree.prototype, "jiangConrathSimilarity", {
  enumerable: false,
  value: jiangConrathSimilarity
});

module.exports = Tree;
