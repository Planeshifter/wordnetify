(function() {
  var Tree, _;

  _ = require('underscore');

  Tree = (function() {
    function Tree(obj) {
      var key, value;
      for (key in obj) {
        value = obj[key];
        this[key] = value;
      }
    }

    Tree.prototype.depth = function(id) {
      var node, ret_depth;
      node = this[id];
      ret_depth;
      if (!node.hypernym) {
        ret_depth = 0;
      } else {
        ret_depth = 1 + this.depth(node.parentId);
      }
      return ret_depth;
    };

    Tree.prototype.getAncestorIDs = function(node) {
      var ret;
      ret = [];
      if (node.hypernyn) {
        ret.push(node.parentId);
        ret = ret.concat(this.getAncestorIDs(this[node.parentId]));
      }
      return ret;
    };

    Tree.prototype.getCommonHypernyms = function(node1, node2) {
      var node1Hypernyms, node2Hypernyms;
      node1Hypernyms = this.getAncestorIDs(node1);
      node2Hypernyms = this.getAncestorIDs(node2);
      return _.intersection(node1Hypernyms, node2Hypernyms);
    };

    Tree.prototype.lowestCommonHypernym = function(node1, node2) {
      var depths, max_depth, synsets;
      synsets = this.getCommonHypernyms(node1, node2);
      depths = synsets.map((function(_this) {
        return function(s) {
          return _this.depth(s);
        };
      })(this));
      max_depth = depths.max();
      return synsets.filter((function(_this) {
        return function(s) {
          return self.depth(s) === max_depth;
        };
      })(this));
    };

    Tree.prototype.getInformation = function(node) {
      var N, N_r, freqSum, prob_hat;
      freqSum = node.tagCount;
      N = 130811;
      N_r = (function(_this) {
        return function(count) {
          return BROWN_COUNTS[count] || 0;
        };
      })(this);
      prob_hat = ((freqSum + 1) / N) * (N_r(freqSum + 1) / N_r(freqSum));
      return -Math.log(prob_hat);
    };

    Tree.prototype.jiangConrathSimilarity = function(node1, node2) {
      var ic1, ic2, ic_lcs, least_common_subsumer;
      ic1 = getInformation(node1);
      ic2 = getInformation(node2);
      least_common_subsumer = this.lowestCommonHypernym(node1, node2);
      ic_lcs = least_common_subsumer != null ? least_common_subsumer : {
        0: getInformation(self[least_common_subsumer])
      };
      return -ic1 - ic2 + 2 * ic_lcs;
    };

    return Tree;

  })();

  module.exports = Tree;

}).call(this);

//# sourceMappingURL=Tree.js.map
