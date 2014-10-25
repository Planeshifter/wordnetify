#!/usr/bin/env node

var program = require('commander');
var fs = require('fs');
var csv = require('csv');
var mime = require('mime');

var synsetRepresentation = require("./synsetRepresentation.js");
var constructSynsetData = require("./constructSynsetData.js");
var mergeWordTrees = require("./mergeWordTrees.js");
var pruneTree = require("./pruneTree.js");
var mergeDocTrees = require("./mergeDocTrees.js");
var pickSynsets = require("./pickSynsets.js");
var propagateWords = require("./propagateWords.js");

var util = require('util');

function createWordNetTree(corpus){
  var wordTreshold = program.threshold || 1;
  var synsetArray = synsetRepresentation(corpus);

  var docTrees = synsetArray.map(function(d){
    var wordTrees = d.map(function(w){
        return constructSynsetData(w);
    });
    return mergeWordTrees(wordTrees);
  });

  // select only one synset per word
  // (synset is chosen according to results of scoring method)
  docTrees = docTrees.map(function(d){
    return pickSynsets(d);
  });

  // console.log(docTrees);

  var outputJSON;
  if (program.combine){
    var finalTree = mergeDocTrees(docTrees);
    if (program.threshold){
      finalTree = pruneTree(finalTree, program.threshold);
    }
    var finalTreePropagated = propagateWords(finalTree);
    var ret = {};
    ret.tree = finalTreePropagated;
    ret.corpus = corpus;
    outputJSON = JSON.stringify(ret);
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
}

program
  .version('0.0.1')
  .option('-i, --input [value]', 'Load data from disk')
  .option('-l, --list <items>','A list of input texts')
  .option('-o, --output [value]', 'Write results to file')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Merge document trees to form corpus tree')
  .option('-d, --delim [value]','Delimiter to split text into documents')
  .parse(process.argv);

var corpus;
var delim = String(program.delim);

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
