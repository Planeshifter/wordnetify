var assert = require("assert");
var arr = require('../lib/Array.js');
var synsetRepresentation = require("../lib/synsetRepresentation.js");

describe('WORDNETIFY_SYNSETS_TREE', function(){
    it('should be a hash table of all synsets', function(){
      return typeof WORDNETIFY_SYNSETS_TREE[115071467] === "object";
  });
});

describe('getCorpusSynsets', function() {
  this.timeout(5000);
  it('should return an array for each word holding an array of synsets for the words of each document', function(){
    var synsetArrays = synsetRepresentation(["oranges and lemons"]);
    var firstDoc = synsetArrays[0];
    var firstWord = firstDoc[0];
    return Object.keys(firstWord).compare(["string","count","baseWords","synsets"]);
  });
});
