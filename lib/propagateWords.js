var _ = require("underscore");

module.exports = function propagateWords(tree){
  for (var key in tree){
    var node = tree[key];
    if (node.isLeaf === true ){
      var current_ancestors = node.data.ancestors;
      current_ancestors.forEach(function(id){
        var parent = tree[id];
        parent.words ? parent.words = parent.words.concat(node.words) : parent.words = node.words;
      });
    }
  }
  for (var key2 in tree){
    var node2 = tree[key2];
    if (node2.words) node2.words = _.countBy(node2.words);
    //console.log(node2.words)
  }
  return tree;
};
