#!/usr/bin/env node

var program = require('commander');
var fs = require('fs');
var csv = require('csv');
var mime = require('mime');
var BPromise = require('bluebird');

var synsetRepresentation = require("./synsetRepresentation.js");
var constructSynsetData = require("./constructSynsetData.js");
var mergeWordTrees = require("./mergeWordTrees.js");
var thresholdTree = require("./pruneTree.js");
var mergeDocTrees = require("./mergeDocTrees.js");
var pickSynsets = require("./pickSynsets.js");
var propagateWords = require("./propagateWords.js");

var util = require('util');

function createWordNetTree(corpus){
  console.time("Step 1: Retrieve Synset Data");
  var wordTreshold = program.threshold || 1;
  var synsetArray = synsetRepresentation(corpus);
  BPromise.all(synsetArray).then(function(){
    console.timeEnd("Step 1: Retrieve Synset Data");
  });
  console.log("Step 2: \n");
  var docTrees = synsetArray.map(function(d, i){
    var docTreeMsg = "Construct Tree for Doc " + i;
    console.time(docTreeMsg);
    var wordTrees = d.map(function(w){
        return constructSynsetData(w);
    });
    BPromise.all(wordTrees).then(function(){
      console.timeEnd(docTreeMsg);
    });
    console.time("Step 3: Form Document Trees");
    return mergeWordTrees(wordTrees);
  });
  BPromise.all(docTrees).then(function(){
    console.timeEnd("Step 3: Form Document Trees");
  });

  console.time("Step 4: Pruning (Word Sense Disambiguation)");
  // select only one synset per word
  // (synset is chosen according to results of scoring method)
  var prunedDocTrees = docTrees.map(function(d){
    return pickSynsets(d);
  });

  BPromise.all(prunedDocTrees).then(function(){
    console.timeEnd("Step 4: Pruning (Word Sense Disambiguation)");
  });

  // console.log(docTrees);

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

program
  .version('0.2.1')
  .option('-i, --input [value]', 'Load data from disk')
  .option('-l, --list <items>','A list of input texts')
  .option('-o, --output [value]', 'Write results to file')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Merge document trees to form corpus tree')
  .option('-d, --delim [value]','Delimiter to split text into documents')
  .option('-p, --pretty','Pretty print of JSON output')
  .option('-v, --verbose','Print additional logging information')
  .parse(process.argv);

var corpus;
var delim = program.delim;

if (program.list){
  delim = delim || ";";
  corpus = program.list.split(delim);
  createWordNetTree(corpus);
} else if (program.input){
  var data = fs.readFileSync(program.input);
  var mime_type = mime.lookup(program.input);

  switch(mime_type){
    case "text/plain" :
      delim = delim || "  ";
      corpus = String(data).replace(/\r\n?/g, "\n").split(delim).clean("");
      createWordNetTree(corpus);
    break;
    case "text/csv"   :
      csv.parse(String(data), function(err, output){
        corpus = output.map(function(d){
          return d[0];
        });
        createWordNetTree(corpus);
      });
    break;
  }
}
