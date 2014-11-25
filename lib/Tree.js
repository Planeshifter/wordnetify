(function() {
  var BROWN, BROWN_COUNTS, BROWN_JSON, IdsToHypernyms, SYNSETS_JSON, Tree, WORDNETIFY_SYNSETS_TREE, fs, key, synset, util, _;

  _ = require('underscore');

  fs = require('fs');

  util = require('util');

  SYNSETS_JSON = fs.readFileSync(__dirname + '/../data/SYNSETS.json');

  WORDNETIFY_SYNSETS_TREE = JSON.parse(SYNSETS_JSON);

  BROWN_JSON = fs.readFileSync(__dirname + '/../data/BROWN.json');

  BROWN = JSON.parse(BROWN_JSON);

  BROWN_COUNTS = _.countBy(BROWN, (function(_this) {
    return function(freq) {
      return freq;
    };
  })(this));

  IdsToHypernyms = function(id) {
    return WORDNETIFY_SYNSETS_TREE[id];
  };

  for (key in WORDNETIFY_SYNSETS_TREE) {
    synset = WORDNETIFY_SYNSETS_TREE[key];
    if (WORDNETIFY_SYNSETS_TREE.hasOwnProperty(key)) {
      synset.tagCount = BROWN[key];
      synset.hypernym = synset.hypernym.map(IdsToHypernyms);
    }
  }

  Tree = (function() {
    function Tree(obj) {
      var value;
      for (key in obj) {
        value = obj[key];
        this[key] = value;
      }
    }

    Tree.prototype.depth = function(id) {
      var node, ret_depth, _ref;
      node = this[id];
      ret_depth;
      if (node.hypernym.length === 0) {
        ret_depth = 0;
      } else {
        ret_depth = 1 + this.depth((_ref = node.hypernym[0]) != null ? _ref.synsetid : void 0);
      }
      return ret_depth;
    };

    Tree.prototype.getAncestorIDs = function(node) {
      debugger;
      var ret;
      ret = [];
      if (node.hypernym.length > 0) {
        ret.push(node.hypernym[0].synsetid);
        ret = ret.concat(this.getAncestorIDs(this[node.hypernym[0].synsetid]));
      }
      return ret;
    };

    Tree.prototype.getCommonHypernyms = function(node1, node2) {
      debugger;
      var node1Hypernyms, node2Hypernyms;
      node1Hypernyms = this.getAncestorIDs(node1);
      node2Hypernyms = this.getAncestorIDs(node2);
      return _.intersection(node1Hypernyms, node2Hypernyms);
    };

    Tree.prototype.lowestCommonHypernym = function(node1, node2) {
      debugger;
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
          return _this.depth(s) === max_depth;
        };
      })(this));
    };

    Tree.prototype.getInformation = function(node) {
      debugger;
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

    Tree.prototype.jiangConrathSimilarity = function(id1, id2) {
      var ic1, ic2, ic_lcs, least_common_subsumer, node1, node2;
      node1 = this[id1];
      node2 = this[id2];
      ic1 = this.getInformation(node1);
      ic2 = this.getInformation(node2);
      least_common_subsumer = this.lowestCommonHypernym(node1, node2);
      ic_lcs = least_common_subsumer != null ? least_common_subsumer : {
        0: getInformation(this[least_common_subsumer])
      };
      return -ic1 - ic2 + 2 * ic_lcs;
    };

    return Tree;

  })();

  WORDNETIFY_SYNSETS_TREE = new Tree(WORDNETIFY_SYNSETS_TREE);

  module.exports = {
    WORDNETIFY_SYNSETS_TREE: WORDNETIFY_SYNSETS_TREE,
    BROWN: BROWN
  };

}).call(this);

//# sourceMappingURL=Tree.js.map
