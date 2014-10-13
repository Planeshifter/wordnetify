#!/usr/bin/env node

var program = require('commander');
var fs = require('fs');

var synsetRepresentation = require("./synsetRepresentation.js");

var util = require('util');

function createWordNetTree(corpus){
  var wordTreshold = program.threshold || 1;
  var synsetArray = synsetRepresentation(corpus);

  var outputJSON = JSON.stringify(synsetArray);

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
  .parse(process.argv);

var corpus;

if (program.list){
  corpus = program.list.split(",");
  createWordNetTree(corpus);
} else if (program.input){
  var data = fs.readFileSync(program.input);
  corpus = String(data).replace(/\r\n?/g, "\n").split("\n").clean("");
  console.log(corpus);
  createWordNetTree(corpus);
}
