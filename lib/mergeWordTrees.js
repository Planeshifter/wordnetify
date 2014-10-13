module.exports = function mergeWordTrees(wordArr){
  var masterTree = wordArr.shift();
  wordArr.forEach(function(w){
    for (var key in w){
      var currentSynset = masterTree[key];
      if (currentSynset){
       	currentSynset.count++;
      	if (currentSynset.words !== null){
      		currentSynset.words = currentSynset.words.concat(w[key].words);
      	}
      } else {
        masterTree[key] = w[key];
      }
    }
  });
 return masterTree;
};
