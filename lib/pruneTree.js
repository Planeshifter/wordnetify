var _ = require("underscore");

module.exports = function pruneTree(tree, threshold){

  function propagateWord(n){
    var parent = tree[n.parentId];
    if (parent && parent.docCount >= threshold){
      var insertWords = _.map(node.words,_.clone);
      parent.words = parent.words ? parent.words.concat(insertWords) : insertWords;
      parent.isLeaf = true;
      parent.ancestors = _.clone(n.ancestors);
    }
    if (parent && parent.docCount < threshold) propagateWord(parent);
  }

  for (var keys1 in tree){
    var node = tree[keys1];
    if (node.words){
      if (node.docCount < threshold) propagateWord(node);
    }
  }

  for (var keys2 in tree){
    var tree_node = tree[keys2];
    if (tree_node.docCount < threshold) delete tree[keys2];
  }
  return tree;
};
