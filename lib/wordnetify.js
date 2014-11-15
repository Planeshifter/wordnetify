(function() {
  var BPromise, constructSynsetData, corpus, createWordNetTree, csv, data, delim, fs, getCorpusTree, mime, mime_type, pickSynsets, program, synsetRepresentation, util;

  program = require('commander');

  fs = require('fs');

  csv = require('csv');

  mime = require('mime');

  BPromise = require('bluebird');

  util = require('util');

  synsetRepresentation = require("./synsetRepresentation");

  constructSynsetData = require("./constructSynsetData");

  pickSynsets = require("./pickSynsets");

  getCorpusTree = require("./corpusTree");


  /*
  thresholdTree = require("./pruneTree.js");
  mergeDocTrees = require("./mergeDocTrees.js");
  propagateWords = require("./propagateWords.js");
   */

  createWordNetTree = function(corpus) {
    var docTrees, prunedDocTrees, synsetArray, wordTreshold;
    console.time("Step 1: Retrieve Synset Data");
    wordTreshold = program.threshold ? program.threshold : 1;
    synsetArray = synsetRepresentation(corpus);
    BPromise.all(synsetArray).then((function(_this) {
      return function() {
        console.timeEnd("Step 1: Retrieve Synset Data");
        return console.time("Step 2: Generate Candidate Sets");
      };
    })(this));
    docTrees = synsetArray.map((function(_this) {
      return function(d, i) {
        var docTreeMsg, wordTrees;
        docTreeMsg = "Construct Candidate Set for Words of Doc " + i;
        console.time(docTreeMsg);
        wordTrees = d.map(function(w) {
          return constructSynsetData(w);
        });
        BPromise.all(wordTrees).then(console.timeEnd(docTreeMsg));
        return wordTrees;
      };
    })(this));
    BPromise.all(docTrees).then((function(_this) {
      return function() {
        console.timeEnd("Step 2: Generate Candidate Sets");
        return console.time("Step 3: Pruning (Word Sense Disambiguation)");
      };
    })(this));
    prunedDocTrees = docTrees.map((function(_this) {
      return function(doc) {
        return pickSynsets(doc);
      };
    })(this));
    return BPromise.all(prunedDocTrees).then((function(_this) {
      return function() {
        return console.timeEnd("Step 3: Pruning (Word Sense Disambiguation)");
      };
    })(this));
  };


  /*
  Command-Line-Interface:
   */

  program.version('0.2.1').option('-i, --input [value]', 'Load data from disk').option('-l, --list <items>', 'A list of input texts').option('-o, --output [value]', 'Write results to file').option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt).option('-c, --combine', 'Merge document trees to form corpus tree').option('-d, --delim [value]', 'Delimiter to split text into documents').option('-p, --pretty', 'Pretty print of JSON output').option('-v, --verbose', 'Print additional logging information').parse(process.argv);

  corpus;

  delim = program.delim;

  if (program.list) {
    delim = delim || ";";
    corpus = program.list.split(delim);
    createWordNetTree(corpus);
  } else if (program.input) {
    data = fs.readFileSync(program.input);
    mime_type = mime.lookup(program.input);
    switch (mime_type) {
      case "text/plain":
        delim = delim || "  ";
        corpus = String(data).replace(/\r\n?/g, "\n").split(delim).clean("");
        createWordNetTree(corpus);
        break;
      case "text/csv":
        csv.parse(String(data), (function(_this) {
          return function(err, output) {
            corpus = output.map(function(d) {
              return d[0];
            });
            return createWordNetTree(corpus);
          };
        })(this));
    }
  }


  /*
  function createWordNetTree(corpus){
  
    var outputJSON;
    if (program.combine){
      var finalTree = mergeDocTrees(prunedDocTrees);
      if (program.threshold){
        finalTree = thresholdTree(finalTree, program.threshold);
      }
      var finalTreePropagated = propagateWords(finalTree);
      var ret = {};
      ret.tree = finalTreePropagated;
      ret.corpus = corpus;
      outputJSON = program.pretty ? JSON.stringify(ret, null, 2) : JSON.stringify(ret);
    } else {
      prunedDocTrees = prunedDocTrees.map(function(tree){
        return propagateWords(tree);
      });
      outputJSON = program.pretty ? JSON.stringify(ret, null, 2) : JSON.stringify(ret);
    }
    if (program.output){
      fs.writeFileSync(program.output, outputJSON);
    } else {
      console.log(outputJSON);
    }
  }
   */

}).call(this);
