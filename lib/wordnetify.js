(function() {
  var BPromise, calculateCounts, constructSynsetData, corpus, createWordNetTree, csv, data, delim, fs, generateCorpusTree, generateWordTree, getCorpusSynsets, mime, mime_type, pickSynsets, program, thresholdDocTree, thresholdTree, thresholdWordTree, util, _ref, _ref1;

  program = require('commander');

  fs = require('fs');

  csv = require('csv');

  mime = require('mime');

  BPromise = require('bluebird');

  util = require('util');

  getCorpusSynsets = require("./synsetRepresentation").getCorpusSynsets;

  constructSynsetData = require("./constructSynsetData").constructSynsetData;

  pickSynsets = require("./pickSynsets");

  _ref = require("./treeGenerator"), generateCorpusTree = _ref.generateCorpusTree, generateWordTree = _ref.generateWordTree;

  thresholdTree = require("./thresholdTree");

  calculateCounts = require("./counting");

  _ref1 = require("./thresholdTree"), thresholdDocTree = _ref1.thresholdDocTree, thresholdWordTree = _ref1.thresholdWordTree;

  createWordNetTree = function(corpus) {
    var docTrees, fPrunedDocTrees, synsetArray, wordTreshold;
    console.time("Step 1: Retrieve Synset Data");
    wordTreshold = program.threshold ? program.threshold : 1;
    synsetArray = getCorpusSynsets(corpus);
    BPromise.all(synsetArray).then((function(_this) {
      return function() {
        console.timeEnd("Step 1: Retrieve Synset Data");
        return console.time("Step 2: Generate Candidate Sets");
      };
    })(this));
    docTrees = synsetArray.map((function(_this) {
      return function(d, index) {
        var docTreeMsg, wordTrees;
        docTreeMsg = "Construct Candidate Set for Words of Doc " + index;
        console.time(docTreeMsg);
        wordTrees = d.map(function(w) {
          return constructSynsetData(w, index);
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
    fPrunedDocTrees = docTrees.map((function(_this) {
      return function(doc) {
        return pickSynsets(doc);
      };
    })(this));
    return BPromise.all(fPrunedDocTrees).then((function(_this) {
      return function(prunedDocTrees) {
        var corpusTree, finalTree, outputJSON, ret;
        console.timeEnd("Step 3: Pruning (Word Sense Disambiguation)");
        outputJSON = '';
        if (program.combine) {
          corpusTree = generateCorpusTree(prunedDocTrees);
          finalTree = calculateCounts(corpusTree);
          if (program.threshold) {
            finalTree = thresholdDocTree(finalTree, program.threshold);
          }
          ret = {};
          ret.tree = finalTree;
          ret.corpus = corpus;
          outputJSON = program.pretty ? JSON.stringify(ret, null, 2) : JSON.stringify(ret);
        } else {
          ret = prunedDocTrees.map(function(doc) {
            return generateWordTree(doc);
          }).map(function(doc) {
            return calculateCounts(doc);
          });
          if (program.threshold) {
            ret = ret.map(function(tree) {
              return thresholdWordTree(tree);
            });
          }
          outputJSON = program.pretty ? JSON.stringify(ret, null, 2) : JSON.stringify(ret);
        }
        if (program.output) {
          return fs.writeFileSync(program.output, outputJSON);
        } else {
          return console.log(outputJSON);
        }
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

}).call(this);

//# sourceMappingURL=wordnetify.js.map
