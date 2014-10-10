var _ = require("underscore");
var arr = require("./array.js");
var logger = require("./logger.js");

module.exports = function pickSynsets(tree, scoringFunction){

	var scoreSynset = scoringFunction || function(w){
		var score = 0;
		for (var i = 0; i < w.data.ancestors.length; i++){
			var id = w.data.ancestors[i];
			var count = tree[id].count;
			score += 	count || 0;
		}
		score = score / w.data.ancestors.length || w.count;
		return score;
	};

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
			w.score = scoreSynset(w);
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
