var _ = require("underscore");
var util = require("util");
var memoize = require("./memoize.js");
var Tree = require("./Tree.js");

var fs = require('fs');
var BROWN_JSON = fs.readFileSync(__dirname + '/../data/BROWN.json');
BROWN = JSON.parse(BROWN_JSON);

BROWN_COUNTS = _.countBy(BROWN, function(freq){
  return freq;
});

module.exports = function constructSynsetData(word){

  var synsetArr = word.synsets;

  var count = word.count;
  var wordTree = new Tree();

  if (synsetArr === null){
  	return wordTree;
  }

  synsetArr.forEach(function(bs){
  	bs.word = Array(word.string);
  });

  synsetArr.forEach(function(bs){
  	bs.ancestors = [];
    bs.isLeaf = true;
    function createAncestorArr(synset){
      wordTree[synset.synsetid] = new SynsetNode(synset, word);
      if (synset.hypernym && synset.hypernym[0]){
        createAncestorArr(synset.hypernym[0]);
        bs.ancestors.push(synset.hypernym[0].synsetid);
        // synset.hypernym = null;
      }
    }
    createAncestorArr(bs);
  });
  return wordTree;
};

function SynsetNode(synset, word){
    if(synset.hypernym && synset.hypernym.length > 0){
    	this.parentId = synset.hypernym[0].synsetid;
    } else {
    	this.parentId = "root";
    }
  this.isLeaf = synset.isLeaf || false;
	this.data = _.clone(synset);
	this.data.hypernym = null;
	this.wordCount = word.count || 1;
  this.docCount = 1;
  this.tagCount = BROWN[this.data.synsetid];
	this.words = synset.word || [];
  var baseWords = word.baseWords.map(function(bw){
    return bw.lemma;
  });
  this.baseWords = this.isLeaf === true ? baseWords : null;
}
