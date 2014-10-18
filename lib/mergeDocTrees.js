module.exports = function mergeDocTrees(docArr){

  var masterTree = docArr.shift();
  docArr.forEach(function(d){
    for (var key in d){
      var currentSynset = masterTree[key];
      if (currentSynset){
       	currentSynset.docCount++;
      	currentSynset.words = currentSynset.words ?
          currentSynset.words.concat(d[key].words) : d[key].words;
      } else {
        masterTree[key] = d[key];
      }
    }
  });
 return masterTree;
};
