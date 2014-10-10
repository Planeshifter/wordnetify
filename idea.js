var BPromise = require("bluebird");
var _ = require("underscore");
var util = require("util");
var memoize = require("./memoize.js");

module.exports = function constructSynsetData(word){

  var synsetArr = word.synsets;
  var count = word.count;
  var wordTree = {};

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
	this.count = word.count || 1;
	this.words = synset.word || null;
}
