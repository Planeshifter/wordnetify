var str = require('./String');
var arr = require('./Array.js');

function Word(str, pos){
    this.lemma = str;
    if (pos){
      this.part_of_speech = pos;
    }
}

Word.prototype = {
	  constructor: Word,
	  getSynsets: function(callback){
		    var self = this;
        var ret = [];
        self.part_of_speech = self.part_of_speech || null;

        function isContained(words){
          return words.some(function(w){
            return w.lemma === self.lemma;
          });
        }

        for (var key in WORDNETIFY_SYNSETS_TREE){
          var current_synset = WORDNETIFY_SYNSETS_TREE[key];
          var contained = isContained(current_synset.words);
          var correctPOS = self.part_of_speech ? self.part_of_speech === current_synset.pos : true;

          if (contained === true && correctPOS){
            ret.push(current_synset);
          }
        }
        return ret;
    }
};

module.exports = Word;
