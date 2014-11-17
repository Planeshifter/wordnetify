(function() {
  var thresholdDocTree, thresholdWordTree;

  thresholdDocTree = function(tree, threshold) {
    var id, synset, _fn;
    _fn = function(synset) {
      if (synset.docCount < threshold) {
        return delete tree[id];
      }
    };
    for (id in tree) {
      synset = tree[id];
      _fn(synset);
    }
    return tree;
  };

  thresholdWordTree = function(tree, threshold) {
    var id, synset, _fn;
    _fn = function(synset) {
      if (synset.wordCount < threshold) {
        return delete tree[id];
      }
    };
    for (id in tree) {
      synset = tree[id];
      _fn(synset);
    }
    return tree;
  };

  module.exports = {
    thresholdDocTree: thresholdDocTree,
    thresholdWordTree: thresholdWordTree
  };

}).call(this);

//# sourceMappingURL=thresholdTree.js.map
