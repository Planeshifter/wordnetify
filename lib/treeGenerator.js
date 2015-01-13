(function() {
  var BinarySearchTree, ProgressBar, SynsetNode, WORDNETIFY_SYNSETS_TREE, generateCorpusTree, generateWordTree, util, _;

  util = require('util');

  _ = require('underscore');

  SynsetNode = require('./constructSynsetData').SynsetNode;

  WORDNETIFY_SYNSETS_TREE = require('./Tree').WORDNETIFY_SYNSETS_TREE;

  ProgressBar = require('progress');

  BinarySearchTree = require('bin-search-tree');

  generateCorpusTree = (function(_this) {
    return function(docs) {
      var allSynsets, attachHypernyms, bsTree, existing_synset, hashTable, parent, progressCorpusTree, synset, _i, _len, _ref, _ref1;
      bsTree = new BinarySearchTree(function(a, b) {
        if (a < b) {
          return -1;
        }
        if (a > b) {
          return 1;
        }
        return 0;
      });
      allSynsets = _.flatten(docs);
      progressCorpusTree = new ProgressBar('Create corpus tree [:bar] :percent', {
        total: _.size(allSynsets)
      });
      attachHypernyms = function(synset, words, docIndices) {
        var existing_synset, insert_synset;
        if (!bsTree.has(synset.synsetid)) {
          insert_synset = new SynsetNode(synset);
          insert_synset.words = words;
          insert_synset.docs = docIndices;
          bsTree.set(synset.synsetid, insert_synset);
        } else {
          existing_synset = bsTree.get(synset.synsetid);
          existing_synset.words = existing_synset.words.concat(words);
          existing_synset.docs = _.union(existing_synset.docs, docIndices);
          docIndices = existing_synset.docs;
        }
        if (synset.hypernym.length > 0) {
          attachHypernyms(synset.hypernym[0], words, docIndices);
        }
      };
      for (_i = 0, _len = allSynsets.length; _i < _len; _i++) {
        synset = allSynsets[_i];
        if (!bsTree.has(synset.synsetid)) {
          bsTree.set(synset.synsetid, synset);
        } else {
          existing_synset = bsTree.get(synset.synsetid);
          existing_synset.docs = _.union(existing_synset.docs, synset.docs);
          existing_synset.words = (_ref = existing_synset.words) != null ? _ref.concat(synset.words) : void 0;
          existing_synset.baseWords = (_ref1 = existing_synset.baseWords) != null ? _ref1.concat(synset.baseWords) : void 0;
        }
        if (synset.parentId && synset.parentId !== 'root') {
          parent = WORDNETIFY_SYNSETS_TREE[synset.parentId];
          attachHypernyms(parent, synset.words, synset.docs);
        }
        progressCorpusTree.tick();
      }
      hashTable = {};
      bsTree.forEach(function(value, key) {
        return hashTable[key] = value;
      });
      return hashTable;
    };
  })(this);

  generateWordTree = (function(_this) {
    return function(doc) {
      var attachHypernyms, existing_synset, hashTable, parent, synset, _i, _len, _ref, _ref1;
      hashTable = {};
      attachHypernyms = function(synset, words, docIndices) {
        var id, _ref;
        id = synset.synsetid;
        if (!(id in hashTable)) {
          hashTable[id] = new SynsetNode(synset);
          hashTable[id].words = words;
          hashTable[id].docs = docIndices;
        } else {
          hashTable[id].words = (_ref = hashTable[id].words) != null ? _ref.concat(words) : void 0;
          hashTable[id].docs = _.union(hashTable[id].docs, docIndices);
        }
        if (synset.hypernym.length > 0) {
          attachHypernyms(synset.hypernym[0], words, hashTable[id].docs);
        }
      };
      for (_i = 0, _len = doc.length; _i < _len; _i++) {
        synset = doc[_i];
        if (!(synset.synsetid in hashTable)) {
          hashTable[synset.synsetid] = synset;
        } else {
          existing_synset = hashTable[synset.synsetid];
          existing_synset.docs = _.union(existing_synset.docs, synset.docs);
          existing_synset.words = (_ref = existing_synset.words) != null ? _ref.concat(synset.words) : void 0;
          existing_synset.baseWords = (_ref1 = existing_synset.baseWords) != null ? _ref1.concat(synset.baseWords) : void 0;
        }
        if (synset.parentId && synset.parentId !== 'root') {
          parent = WORDNETIFY_SYNSETS_TREE[synset.parentId];
          attachHypernyms(parent, synset.words, synset.docs);
        }
      }
      return hashTable;
    };
  })(this);

  module.exports = {
    generateCorpusTree: generateCorpusTree,
    generateWordTree: generateWordTree
  };

}).call(this);

//# sourceMappingURL=treeGenerator.js.map
