var util = require('util');
var _ = require('underscore');

module.exports = function mergeWordTrees(wordArr){
  console.log(util.inspect(wordArr, null, 4));
  var masterTree = wordArr.shift();
  wordArr.forEach(function(w){
    for (var key in w){
      var currentSynset = masterTree[key];
      if (currentSynset){
      		currentSynset.words = currentSynset.words.concat(w[key].words);
          currentSynset.isLeaf = currentSynset.isLeaf && w[key].isLeaf;
      } else {
        masterTree[key] = w[key];
      }
    }
  });
 return masterTree;
};
