var _ = require("underscore");
var arr = require("./Array.js");
var logger = require("./logger.js");

module.exports = function pickSynsets(tree){
	console.log(tree)

	var baseSynsets = _.filter(tree, function(elem){
		return "ancestors" in elem.data;
	});

	var groupedSynsets =  _.groupBy(baseSynsets, "words");
	var allAncestors = baseSynsets.map(function(e){ return e.data.ancestors; });
	allAncestors = _.flatten(allAncestors);
	var ancestorCounts = _.countBy(allAncestors);

	var returnTree = _.clone(tree);

	for (var key in groupedSynsets){
		var wordArray = groupedSynsets[key];

		var scores = [];
		for (var h = 0; h < wordArray.length; h++){
			var w = wordArray[h];

			var similarities = [];
			for (var key2 in groupedSynsets){
				if (key2 !== key){
					var wordArray2 = groupedSynsets[key2];
					var dists = wordArray2.map(function(w2){
						return tree.jiangConrathSimilarity(w, w2);
					});
//					console.log(dists);
				similarities.push(dists.max());
				}
			}

			w.score = similarities.sum();
			console.log(w.score);
			scores.push(w.score);
		}

		var maxScore = scores.max();
		wordArray.forEach(function(w){
      	  if (w.score !== maxScore) {
      	   var ancestors = w.data.ancestors;
      	   delete returnTree[w.data.synsetid];
      	   ancestors.forEach(function(id){
      	     ancestorCounts[id]--;
      	     if (ancestorCounts[id] === 0) delete returnTree[id];
      	   });
      	  }
		});
	}
	return returnTree;
};
