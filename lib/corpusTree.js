(function() {
  var SynsetNode, WORDNETIFY_SYNSETS_TREE, generateCorpusTree, util, _;

  util = require('util');

  _ = require('underscore');

  SynsetNode = require('./constructSynsetData').SynsetNode;

  WORDNETIFY_SYNSETS_TREE = require('./synsetRepresentation').WORDNETIFY_SYNSETS_TREE;

  generateCorpusTree = (function(_this) {
    return function(docs) {
      var allSynsets, attachHypernyms, existing_synset, hashTable, parent, synset, _i, _len;
      hashTable = {};
      allSynsets = _.flatten(docs);
      attachHypernyms = function(synset, words, docIndices) {
        var id;
        id = synset.synsetid;
        if (!(id in hashTable)) {
          hashTable[id] = new SynsetNode(synset);
          hashTable[id].words = words;
          hashTable[id].docs = docIndices;
        } else {
          hashTable[id].words = hashTable[id].words.concat(words);
          hashTable[id].docs = _.union(hashTable[id].docs, docIndices);
        }
        console.log(hashTable[id]);
        if (synset.hypernym.length > 0) {
          attachHypernyms(synset.hypernym[0], words, hashTable[id].docs);
        }
      };
      for (_i = 0, _len = allSynsets.length; _i < _len; _i++) {
        synset = allSynsets[_i];
        if (!(synset.synsetid in hashTable)) {
          hashTable[synset.synsetid] = synset;
        } else {
          existing_synset = hashTable[synset.synsetid];
          existing_synset.docs = _.union(existing_synset.docs, synset.docs);
          existing_synset.words = existing_synset.words.concat(synset.words);
          existing_synset.baseWords = existing_synset.baseWords.concat(synset.baseWords);
        }
        if (synset.parentId && synset.parentId !== 'root') {
          parent = WORDNETIFY_SYNSETS_TREE[synset.parentId];
          attachHypernyms(parent, synset.words, synset.docs);
        }
      }
      return hashTable;
    };
  })(this);

  module.exports = generateCorpusTree;

}).call(this);

//# sourceMappingURL=corpusTree.js.map
