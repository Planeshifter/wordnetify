(function() {
  var SynsetNode, constructSynsetData, util, _;

  _ = require("underscore");

  util = require("util");

  constructSynsetData = function(word, docIndex) {
    if (word.synsets) {
      word.synsets = word.synsets.map((function(_this) {
        return function(s) {
          return new SynsetNode(s, docIndex, word);
        };
      })(this));
    } else {
      word.synsets = null;
    }
    console.log(word.synsets);
    return word.synsets;
  };

  SynsetNode = (function() {
    function SynsetNode(synset, docIndex, word) {
      var _ref;
      if (word == null) {
        word = {};
      }
      console.log(docIndex);
      this.synsetid = synset.synsetid;
      this.isCandidate = !_.isEmpty(word) ? true : false;
      this.data = synset;
      this.wordCount = word.count || 1;
      this.docs = docIndex != null ? [docIndex] : [];
      this.docCount = 1;
      this.words = word.string ? Array(word.string) : [];
      if (word.baseWords) {
        this.baseWords = word.baseWords.map((function(_this) {
          return function(bw) {
            return bw.lemma;
          };
        })(this));
      }
      if (((_ref = synset.hypernym) != null ? _ref.length : void 0) > 0) {
        this.parentId = synset.hypernym[0].synsetid;
      } else {
        this.parentId = "root";
      }
    }

    return SynsetNode;

  })();

  module.exports = {
    constructSynsetData: constructSynsetData,
    SynsetNode: SynsetNode
  };

}).call(this);

//# sourceMappingURL=constructSynsetData.js.map
