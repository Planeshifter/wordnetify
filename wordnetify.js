#!/usr/bin/env node

var program = require('commander');
var fs = require('fs');

var analyzeCorpus = require("./synsetRepresentation.js");
var constructSynsetData = require("./idea.js");
var mergeWordTrees = require("./mergeWordTrees.js");
var pruneTree = require("./pruneTree.js");
var mergeDocTrees = require("./mergeDocTrees.js");
var pickSynsets = require("./pickSynsets.js");
var propagateWords = require("./propagateWords.js");

function createWordNetTree(corpus){
  var wordTreshold = program.threshold || 1;
  analyzeCorpus(corpus).then(function(corpus){
    var docTrees = corpus.map(function(d){
      var wordTrees = d.map(function(w){
          return constructSynsetData(w);
      });
      return mergeWordTrees(wordTrees);
    });
    docTrees = docTrees.map(function(d){
      return pickSynsets(d);
    });
    docTrees = docTrees.map(function(d){
      return pruneTree(d, wordTreshold);
    });

    var outputJSON;
    if (program.combine){
      var finalTree = mergeDocTrees(docTrees);
      var finalTreePropagated = propagateWords(finalTree);
      outputJSON = JSON.stringify(finalTreePropagated);
    } else {
      docsTrees = docTrees.map(function(tree){
        return propagateWords(tree);
      });
      outputJSON = JSON.stringify(docTrees);
    }
    if (program.output){
      fs.writeFileSync(program.output, outputJSON);
    } else {
      console.log(outputJSON);
    }
  });
}

program
  .version('0.0.1')
  .option('-i, --input [value]', 'Load data from disk')
  .option('-l, --list <items>','A list of input texts')
  .option('-o, --output [value]', 'Write results to file.')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Indicates that document trees should be merged to form corpus tree')
  .parse(process.argv);

var corpus;
if (program.list){
  corpus = program.list.split(",");
  createWordNetTree(corpus);
} else if (program.input){
  var data = fs.readFileSync(program.input);
  corpus = String(data).replace(/\r\n?/g, "\n").split("\n");
  createWordNetTree(corpus);
}
