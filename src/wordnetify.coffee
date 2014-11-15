#!/usr/bin/env node

program = require 'commander'
fs = require 'fs'
csv = require 'csv'
mime = require 'mime'
BPromise = require 'bluebird'
util = require 'util'

{getCorpusSynsets} = require "./synsetRepresentation"
{constructSynsetData} = require "./constructSynsetData"
pickSynsets = require "./pickSynsets"
getCorpusTree = require "./corpusTree"

###
thresholdTree = require("./pruneTree.js");
mergeDocTrees = require("./mergeDocTrees.js");
propagateWords = require("./propagateWords.js");
###

createWordNetTree = (corpus) ->
    console.time "Step 1: Retrieve Synset Data"
    wordTreshold = if program.threshold then program.threshold else  1
    synsetArray = getCorpusSynsets(corpus)
    BPromise.all(synsetArray).then () =>
      console.timeEnd "Step 1: Retrieve Synset Data"
      console.time "Step 2: Generate Candidate Sets"

    docTrees = synsetArray.map( (d, i) =>
      docTreeMsg = "Construct Candidate Set for Words of Doc " + i
      console.time(docTreeMsg)
      wordTrees = d.map( (w) => constructSynsetData(w) )
      BPromise.all(wordTrees).then console.timeEnd(docTreeMsg)
      return wordTrees
    )
    BPromise.all(docTrees).then () =>
      console.timeEnd "Step 2: Generate Candidate Sets"
      console.time "Step 3: Pruning (Word Sense Disambiguation)"
    fPrunedDocTrees = docTrees.map( (doc) =>
      pickSynsets(doc)
    )
    BPromise.all(fPrunedDocTrees).then (prunedDocTrees) =>
      console.log( util.inspect prunedDocTrees, null, 4)
      console.timeEnd("Step 3: Pruning (Word Sense Disambiguation)")
      outputJSON = ''
      if program.combine
        finalTree = getCorpusTree(prunedDocTrees)
        if program.threshold
          finalTree = thresholdTree(finalTree, program.threshold)



###
Command-Line-Interface:
###

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
  .parse(process.argv)

corpus;
delim = program.delim

if program.list
  delim = delim or ";"
  corpus = program.list.split(delim)
  createWordNetTree(corpus)
else if (program.input)
  data = fs.readFileSync(program.input)
  mime_type = mime.lookup(program.input)
  switch mime_type
    when "text/plain"
      delim = delim or "  "
      corpus = String(data).replace(/\r\n?/g, "\n").split(delim).clean("")
      createWordNetTree(corpus)
    when "text/csv"
      csv.parse(String(data), (err, output) =>
        corpus = output.map( (d) => d[0] )
        createWordNetTree(corpus)
      )

###
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
###
