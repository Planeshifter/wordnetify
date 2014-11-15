(function() {
  var Word, arr, str, _;

  str = require('./String.js');

  arr = require('./Array.js');

  _ = require('underscore');

  Word = (function() {
    function Word(lemma, part_of_speech) {
      this.lemma = lemma;
      this.part_of_speech = part_of_speech != null ? part_of_speech : null;
    }

    Word.prototype.getSynsets = function(callback) {
      var contained, correctPOS, insert_synset, isContained, ret, synset, _i, _len, _ref;
      ret = [];
      isContained = (function(_this) {
        return function(words) {
          return words.some(function(w) {
            return w.lemma === self.lemma;
          });
        };
      })(this);
      _ref = global.WORDNETIFY_SYNSETS_TREE;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        synset = _ref[_i];
        console.log(global.WORDNETIFY_SYNSETS_TREE);
        contained = isContained(synset.words);
        correctPOS = this.part_of_speech ? this.part_of_speech === synset.pos : true;
        if (contained === true && correctPOS) {
          insert_synset = _.clone(synset);
          ret.push(insert_synset);
        }
      }
      return ret;
    };

    return Word;

  })();

  module.exports = Word;

}).call(this);
