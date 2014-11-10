var _ = require("underscore");
var arr = require("./Array.js");
var logger = require("./logger.js");
var fs = require("fs");

module.exports = function pickSynsets(tree){
	//console.log(tree)

	var baseSynsets = _.filter(tree, function(elem){
		return "ancestors" in elem.data;
	});

	var groupedSynsets =  _.groupBy(baseSynsets, "words");
	console.log(groupedSynsets)
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
				//console.log(dists);
				similarities.push(dists.max());
				}
			}

			w.score = similarities.sum();
			scores.push(w.score);
		}

		var maxScore = scores.max();
		logger.log("info","Score Array",{scores: scores, maxScore: maxScore});
		var chosen = false;

		for (var l = 0; l < wordArray.length; l++){
			var word = wordArray[l];
			logger.log("info","word",word.baseWords);
			if (word.score !== maxScore || chosen === true){
				var ancestors = word.data.ancestors;
				if (word.isLeaf === true){
					delete returnTree[word.data.synsetid];
				} else {
					if(returnTree[word.data.synsetid]){
						returnTree[word.data.synsetid].words = [];
					}
				}

				ancestors.forEach(function(id){
					logger.log("info","ancestor",{id:id, count:ancestorCounts[id]});
					ancestorCounts[id]--;
					if (ancestorCounts[id] === 0 && returnTree[id].isLeaf === false){
						logger.log("info","synset definition",{definition: returnTree[id].data.definition,
						words: returnTree[id].data.words});
						for (var i = 0; i < wordArray.length; i++){
							console.log(id)
							console.log(wordArray[i].data.synsetid == id)
							if (wordArray[i].data.synsetid === id){
							logger.log("info","detected problem",{word: returnTree[id].data.words});
							}
						}
						delete returnTree[id];
					}
				});
			} else {
				logger.log("info","word to delete", {def:word});
				chosen = true;
			}
		}

	}
	logger.log("info","Return Tree",{returnTree: returnTree});
	fs.writeFileSync("returnTree.json",JSON.stringify(returnTree));
	return returnTree;
};
