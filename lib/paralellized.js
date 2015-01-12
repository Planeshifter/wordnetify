var Parallel = require("paralleljs");
constructSynsetData = require("./constructSynsetData").constructSynsetData;
SynsetNode = require("./constructSynsetData").SynsetNode;
pickSynsets = require("./pickSynsets");
BPromise = require('bluebird');
WORDNETIFY_SYNSETS_TREE = require("./Tree").WORDNETIFY_SYNSETS_TREE;

module.exports = function processDocArray(docs){
  var p = new Parallel(docs,{synchronous: false,
  env: {
    BPromise: BPromise,
    WORDNETIFY_SYNSETS_TREE: WORDNETIFY_SYNSETS_TREE
  }});

  function cubeRoot(n) { return Math.pow(n, 1 / 3); }

  // Require a function
  p.require(constructSynsetData);
  p.require(SynsetNode);
  p.require(pickSynsets);
  p.require(WORDNETIFY_SYNSETS_TREE);

  var ret = p.map(function (doc, index) {
    var wordTrees = doc.map(function(w){return constructSynsetData(w, index);});
    doc = wordTrees.filter(function(word){ return word !== null; });
    if(doc)
      doc = pickSynsets(doc);
    else
      doc = null;
    return doc;
  });

  return ret;
};
