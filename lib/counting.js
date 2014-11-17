(function() {
  var calculateCounts, _;

  _ = require('underscore');

  calculateCounts = function(tree) {
    var id, synset, _fn;
    _fn = function(synset) {
      synset.docCount = synset.docs.length;
      synset.wordCount = synset.words.length;
      return synset.words = _.countBy(synset.words);
    };
    for (id in tree) {
      synset = tree[id];
      _fn(synset);
    }
    return tree;
  };

  module.exports = calculateCounts;

}).call(this);

//# sourceMappingURL=counting.js.map
