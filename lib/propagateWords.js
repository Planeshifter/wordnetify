var _ = require("underscore");

module.exports = function propagateWords(tree){

   function propagateUp(node, words){
      if(node.parentId !== "root"){
        var parent = tree[node.parentId];
        if (parent){
          parent.words = parent.words ? parent.words.concat(words) : words;
          propagateUp(parent, words);
        }
      }
   }

   var activeNodes = [];
   for (var key in tree){
     var node = tree[key];
     if (node.words !== null){
       activeNodes.push(node);
     }
   }

   activeNodes.forEach(function(n){
     propagateUp(n, n.words);
   });

   for (var key2 in tree){
     var node2 = tree[key2];
     if (node2.words){
       node2.wordCount = _.size(node2.words);
       node2.words = _.countBy(node2.words);
     }
   }
   return tree;
};
