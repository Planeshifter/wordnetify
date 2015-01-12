(function() {
  var arr, findCorrelatedWithID, fs, output, util, _;

  util = require('util');

  fs = require('fs');

  _ = require('underscore');

  arr = require('./Array');

  output = JSON.parse(fs.readFileSync('../kidneyforums.json'));

  findCorrelatedWithID = function(output, synsetid) {
    var key, synset2, synsetList, synset_docs, synset_words, tree;
    tree = output.tree;
    synset_docs = tree[synsetid].docs;
    synset_words = Object.keys(tree[synsetid].words);
    console.log(synset_words);
    for (key in tree) {
      synset2 = tree[key];
      if (!synset2.docs.containsAny(synset_docs)) {
        delete tree[key];
      }
      if (_.intersection(Object.keys(synset2.words), synset_words).length > 0) {
        delete tree[key];
      } else {
        tree[key].docs = _.intersection(synset_docs, synset2.docs);
        tree[key].docCount = tree[key].docs.length;
        tree[key].wordCount = tree[key].docCount;
      }
      if (synset2.isCandidate === false) {
        delete tree[key];
      }
    }
    synsetList = _.map(tree, (function(_this) {
      return function(e) {
        var o;
        o = {};
        o.words = e.data.words.map(function(e) {
          return e.lemma;
        }).splice(0, 3);
        o.definition = e.data.definition;
        o.docCount = e.docCount;
        return o;
      };
    })(this));
    return fs.writeFileSync("kidneyforumsHusband.json", JSON.stringify(synsetList, null, 2));
  };

  findCorrelatedWithID(output, "110213586");

}).call(this);

//# sourceMappingURL=findCorrelatedSynsets.js.map
