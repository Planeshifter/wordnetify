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
   var pushWords = {};

   for (var key in tree){
     var node = tree[key];
     if (node.words.length !== 0){
       pushWords[key] = _.clone(node.words);
       activeNodes.push(node);
     }
   }

   activeNodes.forEach(function(n){
     propagateUp(n, pushWords[n.data.synsetid]);
   });


   for (var key2 in tree){
     var node2 = tree[key2];
     if (node2.words){
       node2.wordCount = _.size(node2.words);
       node2.words = _.countBy(node2.words);
     }
   }

   for (var key3 in tree){
     var node = tree[key3];
     if (node.wordCount == 0){
       delete tree[key3];
     }
   }

  return tree;
};
