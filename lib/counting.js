(function() {
  var ProgressBar, calculateCounts, _;

  _ = require('underscore');

  ProgressBar = require('progress');

  calculateCounts = function(tree) {
    var id, progressBarCounting, synset, tree_length, _fn;
    tree_length = _.size(tree);
    progressBarCounting = new ProgressBar('Calculate word counts [:bar] :percent :etas', {
      total: tree_length
    });
    _fn = function(synset) {
      synset.docCount = synset.docs.length;
      synset.wordCount = synset.words.length;
      return synset.words = _.countBy(synset.words);
    };
    for (id in tree) {
      synset = tree[id];
      _fn(synset);
      progressBarCounting.tick();
    }
    return tree;
  };

  module.exports = calculateCounts;

}).call(this);

//# sourceMappingURL=counting.js.map
