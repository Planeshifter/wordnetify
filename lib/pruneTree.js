var _ = require("underscore");

module.exports = function pruneTree(tree, treshold){
  for (var key in tree){
  	var node = tree[key];
  	if (node.words){
  		function propagateWord(n){
  			var parent = tree[n.parentId];
  			if (parent && parent.count >= treshold){
  				parent.words = parent.words ? parent.words = parent.words.concat(node.words) : parent.words = node.words;
  			}
  			if (parent && parent.count < treshold) propagateWord(parent);
  		}
  		if (node.count < treshold) propagateWord(node);
  	}
  }
  for (var keys in tree){
    var tree_node = tree[keys];
    if (tree_node.count < treshold) delete tree[keys];
  }
  return tree;
};
