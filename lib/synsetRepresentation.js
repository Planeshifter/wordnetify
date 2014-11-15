(function() {
  var BPromise, BROWN, BROWN_COUNTS, BROWN_JSON, IdsToHypernyms, SYNSETS_JSON, WORDNETIFY_SYNSETS_TREE, Word, arr, createDocTree, fs, getCorpusSynsets, getWordSynsets, key, logger, memoize, morphy, str, synset, tm, util, _;

  tm = require("text-miner");

  BPromise = require("bluebird");

  _ = require("underscore");

  util = require("util");

  logger = require("./logger");

  morphy = require("./morphy");

  memoize = require("./memoize");

  fs = require('fs');

  str = require('./String.js');

  arr = require('./Array.js');

  SYNSETS_JSON = fs.readFileSync(__dirname + '/../data/SYNSETS.json');

  WORDNETIFY_SYNSETS_TREE = JSON.parse(SYNSETS_JSON);

  BROWN_JSON = fs.readFileSync(__dirname + '/../data/BROWN.json');

  BROWN = JSON.parse(BROWN_JSON);

  BROWN_COUNTS = _.countBy(BROWN, (function(_this) {
    return function(freq) {
      return freq;
    };
  })(this));

  IdsToHypernyms = function(id) {
    return WORDNETIFY_SYNSETS_TREE[id];
  };

  for (key in WORDNETIFY_SYNSETS_TREE) {
    synset = WORDNETIFY_SYNSETS_TREE[key];
    if (WORDNETIFY_SYNSETS_TREE.hasOwnProperty(key)) {
      synset.tagCount = BROWN[key];
      synset.hypernym = synset.hypernym.map(IdsToHypernyms);
    }
  }

  Word = (function() {
    function Word(lemma, part_of_speech) {
      this.lemma = lemma;
      this.part_of_speech = part_of_speech != null ? part_of_speech : null;
    }

    Word.prototype.getSynsets = function(callback) {
      var contained, correctPOS, insert_synset, isContained, ret;
      ret = [];
      isContained = (function(_this) {
        return function(words) {
          debugger;
          return words.some(function(w) {
            return w.lemma === _this.lemma;
          });
        };
      })(this);
      for (key in WORDNETIFY_SYNSETS_TREE) {
        synset = WORDNETIFY_SYNSETS_TREE[key];
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

  getCorpusSynsets = function(docs) {
    var corpus, res, wordArrays;
    if (Array.isArray(docs) === false) {
      docs = Array(docs);
    }
    corpus = new tm.Corpus(docs);
    corpus = corpus.removeInterpunctuation().removeNewlines().toLower().clean().removeWords(tm.STOPWORDS.EN).clean();
    wordArrays = corpus.documents.map((function(_this) {
      return function(x) {
        return x.split(" ");
      };
    })(this));
    logger.log("info", "This is the array of word arrays", {
      wordArrays: wordArrays
    });
    wordArrays = wordArrays.map((function(_this) {
      return function(arr) {
        var res;
        res = arr.reduce(function(a, b) {
          var existingWord, word;
          existingWord = a.filter(function(x) {
            return x.string === b;
          });
          if (existingWord.length > 0) {
            existingWord[0].count++;
            return a;
          } else {
            word = {};
            word.string = b;
            word.count = 1;
            return a.concat(word);
          }
        }, []);
        return res;
      };
    })(this));
    logger.log("info", "This is the array of unique word arrays", {
      uniqueWordArrays: wordArrays
    });
    res = wordArrays.map((function(_this) {
      return function(arr) {
        return createDocTree(arr);
      };
    })(this));
    logger.log("info", "These are the doc synset Trees", {
      docTrees: res
    });
    return res;
  };

  createDocTree = function(wordArray) {
    var baseWordArray, synsetsArray;
    baseWordArray = wordArray.map((function(_this) {
      return function(x) {
        console.log(morphy(x.string, "n"));
        x.baseWords = morphy(x.string, "n");
        logger.log("info", "Morphy base words", {
          x: x
        });
        return x;
      };
    })(this));
    synsetsArray = baseWordArray.map((function(_this) {
      return function(w) {
        var bw;
        if (!_.isEmpty(w.baseWords)) {
          bw = new Word(w.baseWords[0].lemma, "n");
          w.synsets = getWordSynsets(bw);
          return w;
        } else {
          w.synsets = null;
          return w;
        }
      };
    })(this));
    return synsetsArray;
  };

  getWordSynsets = memoize((function(_this) {
    return function(word) {
      return word.getSynsets();
    };
  })(this));

  module.exports = getCorpusSynsets;

}).call(this);
