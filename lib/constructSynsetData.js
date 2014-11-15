(function() {
  var SynsetNode, constructSynsetData, util, _;

  _ = require("underscore");

  util = require("util");

  constructSynsetData = function(word) {
    if (word.synsets) {
      return word.synsets = word.synsets.map((function(_this) {
        return function(s) {
          return new SynsetNode(s, word);
        };
      })(this));
    } else {
      return word.synsets = null;
    }
  };

  SynsetNode = (function() {
    function SynsetNode(synset, word) {
      var _ref;
      console.log(synset);
      this.synsetid = synset.synsetid;
      this.isCandidate = true;
      this.data = synset;
      this.wordCount = word.count || 1;
      this.docCount = 1;
      this.words = synset.word || [];
      this.baseWords = word.baseWords.map((function(_this) {
        return function(bw) {
          return bw.lemma;
        };
      })(this));
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
