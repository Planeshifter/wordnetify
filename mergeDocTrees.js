module.exports = function mergeDocTrees(docArr){

  docArr.forEach(function(d){
    for (var key in d){
      d[key].count = 1;
    }
  });

  var masterTree = docArr.shift();
    //console.log(masterTree)
  docArr.forEach(function(d){
    for (var key in d){
      var currentSynset = masterTree[key];
      if (currentSynset){
       	currentSynset.count++;
      	currentSynset.words ? currentSynset.words = currentSynset.words.concat(d[key].words) : currentSynset.words = d[key].words;
      } else {
        masterTree[key] = d[key];
      }
    }
  });
 return masterTree;
};
