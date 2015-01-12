#!/usr/bin/env node;
var BPromise, calculateCounts, child_process, cluster, constructSynsetData, createWordNetTree, csv, fs, generateCorpusTree, generatePDF, generateWordTree, getCorpusSynsets, mime, pickSynsets, prepareWordnetTree, program, querystring, rp, thresholdDocTree, thresholdTree, thresholdWordTree, util, writePDF, _ref, _ref1;

program = require('commander');

fs = require('fs');

csv = require('csv');

mime = require('mime');

BPromise = require('bluebird');

util = require('util');

rp = require('request-promise');

querystring = require('querystring');

child_process = require('child_process');

getCorpusSynsets = require("./synsetRepresentation").getCorpusSynsets;

constructSynsetData = require("./constructSynsetData").constructSynsetData;

pickSynsets = require("./pickSynsets");

_ref = require("./treeGenerator"), generateCorpusTree = _ref.generateCorpusTree, generateWordTree = _ref.generateWordTree;

thresholdTree = require("./thresholdTree");

calculateCounts = require("./counting");

_ref1 = require("./thresholdTree"), thresholdDocTree = _ref1.thresholdDocTree, thresholdWordTree = _ref1.thresholdWordTree;

writePDF = require("./writePDF");

cluster = {};

prepareWordnetTree = function(options) {
  corpus;
  var corpus, data, delim, mime_type;
  delim = options.delim;
  if (options.list) {
    delim = delim || ";";
    corpus = options.list.split(delim);
    cluster.server = child_process.fork(__dirname + '/cluster.js');
    return cluster.server.on('message', (function(_this) {
      return function(m) {
        console.log('Worker connection established:', m.msg);
        return createWordNetTree(corpus, options);
      };
    })(this));
  } else if (options.input) {
    data = fs.readFileSync(options.input);
    mime_type = mime.lookup(options.input);
    switch (mime_type) {
      case "text/plain":
        delim = delim || "  ";
        corpus = String(data).replace(/\r\n?/g, "\n").split(delim).clean("");
        console.log('Number of Documents to analyze: ' + corpus.length);
        cluster = child_process.fork(__dirname + '/cluster.js');
        return cluster.on('message', (function(_this) {
          return function(m) {
            console.log('PARENT got message:', m);
            return createWordNetTree(corpus, options);
          };
        })(this));
      case "text/csv":
        return csv.parse(String(data), (function(_this) {
          return function(err, output) {
            corpus = output.map(function(d) {
              return d[0];
            });
            console.log('Number of Documents to analyze: ' + corpus.length);
            return createWordNetTree(corpus, options);
          };
        })(this));
      case "application/json":
        corpus = JSON.parse(data);
        console.log('Number of Documents to analyze: ' + corpus.length);
        return createWordNetTree(corpus, options);
    }
  }
};

createWordNetTree = function(corpus, options) {
  var fPrunedDocTrees, synsetArray, wordTreshold;
  console.time("Step 1: Retrieve Synset Data");
  wordTreshold = options.threshold ? options.threshold : 1;
  synsetArray = getCorpusSynsets(corpus);
  BPromise.all(synsetArray).then((function(_this) {
    return function() {
      return console.timeEnd("Step 1: Retrieve Synset Data");
    };
  })(this));
  fPrunedDocTrees = synsetArray.map((function(_this) {
    return function(d, index) {
      var postData;
      postData = {
        doc: JSON.stringify(d),
        index: index
      };
      return rp.post('http://localhost:8000/getBestSynsets', {
        body: querystring.stringify(postData)
      }).then(function(response) {
        return JSON.parse(response);
      });
    };
  })(this)).filter((function(_this) {
    return function(doc) {
      return doc !== null;
    };
  })(this));
  return BPromise.all(fPrunedDocTrees).then((function(_this) {
    return function(prunedDocTrees) {
      var corpusTree, finalTree, outputJSON, ret;
      cluster.server.kill('SIGKILL');
      outputJSON = '';
      if (options.combine) {
        corpusTree = generateCorpusTree(prunedDocTrees);
        finalTree = calculateCounts(corpusTree);
        if (options.threshold) {
          finalTree = thresholdDocTree(finalTree, options.threshold);
        }
        ret = {};
        ret.tree = finalTree;
        ret.corpus = corpus;
        outputJSON = options.pretty ? JSON.stringify(ret, null, 2) : JSON.stringify(ret);
      } else {
        ret = prunedDocTrees.map(function(doc) {
          return generateWordTree(doc);
        }).map(function(doc) {
          return calculateCounts(doc);
        });
        if (options.threshold) {
          ret = ret.map(function(tree) {
            return thresholdWordTree(tree);
          });
        }
        outputJSON = options.pretty ? JSON.stringify(ret, null, 2) : JSON.stringify(ret);
      }
      if (options.output) {
        fs.writeFileSync(options.output, outputJSON);
      } else {
        console.log(outputJSON);
      }
    };
  })(this)).then((function(_this) {
    return function(d) {
      var code;
      console.log("Job successfully completed.");
      return process.exit(code = 0);
    };
  })(this))["catch"]((function(_this) {
    return function(e) {
      var code;
      console.log("Job aborted with errors.");
      return process.exit(code = 1);
    };
  })(this));
};

generatePDF = function(options) {
  var file, pdfOptions, synsetTree, writeStream;
  file = fs.readFileSync(options.input);
  synsetTree = JSON.parse(file);
  pdfOptions = {};
  pdfOptions.includeDocs = options.includeDocs;
  pdfOptions.includeWords = options.includeWords;
  pdfOptions.docReferences = options.docReferences;
  writeStream = writePDF(synsetTree, options.output, pdfOptions);
  return writeStream.on("close", (function(_this) {
    return function() {
      var code;
      console.log("Job successfully completed.");
      return process.exit(code = 0);
    };
  })(this)).on("error", (function(_this) {
    return function() {
      var code;
      console.log("Job aborted with errors.");
      return process.exit(code = 1);
    };
  })(this));
};


/*
Command-Line-Interface:
 */

program.version('0.2.1').option('-v, --verbose', 'Print additional logging information');

program.command('PDF').description('generate pdf report').option('-i, --input [value]', 'Input JSON synset tree file').option('-o, --output [value]', 'File name of generated PDF').option('-d, --includeDocs', 'Append documents to report').option('-r,--docReferences', 'Include document IDs for each synset').option('-w,--includeWords', 'Include words for each synset').action(generatePDF);

program.command('JSON').description('export synset tree to JSON format').option('-i, --input [value]', 'Load data from disk').option('-l, --list <items>', 'A list of input texts').option('-o, --output [value]', 'Write results to file').option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt).option('-c, --combine', 'Merge document trees to form corpus tree').option('-d, --delim [value]', 'Delimiter to split text into documents').option('-p, --pretty', 'Pretty print of JSON output').action(prepareWordnetTree);

program.parse(process.argv);
