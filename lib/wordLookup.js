(function() {
  var SYNSETS_JSON, WORDNETIFY_SYNSETS_TREE, WORDNETIFY_WORD_LOOKUP, fs, id, synset;

  fs = require('fs');

  SYNSETS_JSON = fs.readFileSync(__dirname + '/../data/SYNSETS.json');

  WORDNETIFY_SYNSETS_TREE = JSON.parse(SYNSETS_JSON);

  WORDNETIFY_WORD_LOOKUP = {};

  for (id in WORDNETIFY_SYNSETS_TREE) {
    synset = WORDNETIFY_SYNSETS_TREE[id];
    synset.words.map((function(_this) {
      return function(w) {
        return w.lemma;
      };
    })(this)).forEach((function(_this) {
      return function(w) {
        if (!WORDNETIFY_WORD_LOOKUP.hasOwnProperty(w)) {
          return WORDNETIFY_WORD_LOOKUP[w] = [id];
        } else {
          console.log(w);
          return WORDNETIFY_WORD_LOOKUP[w].push(id);
        }
      };
    })(this));
  }

  fs.writeFileSync('LOOKUP.json', JSON.stringify(WORDNETIFY_WORD_LOOKUP));

}).call(this);

//# sourceMappingURL=wordLookup.js.map
