(function() {
  var BPromise, DICTIONARY, EXCEPTIONS, MORPHY_SUBSTITUTIONS, ProgressBar, Vocabulary, WORDNETIFY_SYNSETS_TREE, WORD_LOOKUP, Word, arr, createDocTree, exports, fs, getCorpusSynsets, getWordSynsets, memoize, morphy, str, synsetidArr, tm, util, word, _;

  tm = require("text-miner");

  BPromise = require("bluebird");

  _ = require("underscore");

  util = require("util");

  ProgressBar = require('progress');

  memoize = require("./memoize");

  fs = require('graceful-fs');

  str = require('./String.js');

  arr = require('./Array.js');

  WORDNETIFY_SYNSETS_TREE = require('./Tree').WORDNETIFY_SYNSETS_TREE;

  WORD_LOOKUP = JSON.parse(fs.readFileSync(__dirname + "/../data/LOOKUP.json"));

  for (word in WORD_LOOKUP) {
    synsetidArr = WORD_LOOKUP[word];
    WORD_LOOKUP[word] = synsetidArr.map((function(_this) {
      return function(id) {
        return WORDNETIFY_SYNSETS_TREE[id];
      };
    })(this));
  }

  Vocabulary = (function() {
    function Vocabulary() {
      this.dict = new Map();
    }

    Vocabulary.prototype.add = function(word) {
      this.dict.set(this.dict.size, word);
      return this.dict.size;
    };

    Vocabulary.prototype.getSize = function() {
      return this.dict.size;
    };

    Vocabulary.prototype.getArray = function() {
      var ret;
      ret = [];
      this.dict.forEach((function(_this) {
        return function(value, key) {
          return ret.push(value);
        };
      })(this));
      return ret;
    };

    return Vocabulary;

  })();

  Word = (function() {
    function Word(lemma, part_of_speech) {
      this.lemma = lemma;
      this.part_of_speech = part_of_speech != null ? part_of_speech : null;
    }

    Word.prototype.getSynsets = function(callback) {
      var ret;
      ret = WORD_LOOKUP[this.lemma] ? WORD_LOOKUP[this.lemma] : [];
      ret = ret.filter((function(_this) {
        return function(synset) {
          if (_this.part_of_speech) {
            return synset.pos === _this.part_of_speech;
          } else {
            return true;
          }
        };
      })(this));
      return ret;
    };

    return Word;

  })();

  DICTIONARY = JSON.parse(fs.readFileSync(__dirname + "/../data/DICTIONARY.json"));

  EXCEPTIONS = JSON.parse(fs.readFileSync(__dirname + "/../data/EXCEPTIONS.json"));

  MORPHY_SUBSTITUTIONS = {
    NOUN: [
      {
        suffix: 's',
        ending: ''
      }, {
        suffix: 'ses',
        ending: 's'
      }, {
        suffix: 'ves',
        ending: 'f'
      }, {
        suffix: 'xes',
        ending: 'x'
      }, {
        suffix: 'zes',
        ending: 'z'
      }, {
        suffix: 'ches',
        ending: 'ch'
      }, {
        suffix: 'shes',
        ending: 'sh'
      }, {
        suffix: 'men',
        ending: 'man'
      }, {
        suffix: 'ies',
        ending: 'y'
      }
    ],
    VERB: [
      {
        suffix: 's',
        ending: ''
      }, {
        suffix: 'ies',
        ending: 'y'
      }, {
        suffix: 'es',
        ending: 'e'
      }, {
        suffix: 'es',
        ending: ''
      }, {
        suffix: 'ed',
        ending: 'e'
      }, {
        suffix: 'ed',
        ending: ''
      }, {
        suffix: 'ing',
        ending: 'e'
      }, {
        suffix: 'ing',
        ending: ''
      }
    ],
    ADJECTIVE: [
      {
        suffix: 'er',
        ending: ''
      }, {
        suffix: 'est',
        ending: ''
      }, {
        suffix: 'er',
        ending: 'e'
      }, {
        suffix: 'est',
        ending: 'e'
      }
    ]
  };

  morphy = function(input_str, pos) {
    debugger;
    var base_word, current, exception_morphs, found_exceptions, i, index, q, reducedArray, resArray, rulesOfDetachment, substitutions, suffix;
    rulesOfDetachment = (function(_this) {
      return function(word, substitutions) {
        var i, new_ending, new_word, recResult, result, suffix;
        result = [];
        DICTIONARY.filter(function(elem) {
          return elem.lemma === word;
        }).forEach(function(elem) {
          var obj;
          if (elem.pos === pos) {
            obj = new Word(elem.lemma);
            obj.part_of_speech = elem.pos;
            return result.push(obj);
          }
        });
        i = 0;
        while (i < substitutions.length) {
          suffix = substitutions[i].suffix;
          new_ending = substitutions[i].ending;
          if (word.endsWith(suffix) === true) {
            new_word = word.substring(0, word.length - suffix.length) + new_ending;
            substitutions.splice(i, 1);
            if (new_word.endsWith("e") && !word.endsWith("e")) {
              substitutions.push({
                suffix: "e",
                ending: ""
              });
            }
            recResult = rulesOfDetachment(new_word, substitutions);
            if (Array.isArray(recResult)) {
              result = result.concat(recResult);
            } else {
              result.push(recResult);
            }
          }
          i++;
        }
        return result;
      };
    })(this);
    if (!pos) {
      arr = ["n", "v", "a", "r", "s"];
      resArray = [];
      i = 0;
      while (i <= 4) {
        resArray.push(morphy(input_str, arr[i]));
        i++;
      }
      reducedArray = [];
      q = 0;
      while (q < resArray.length) {
        current = resArray[q];
        reducedArray.push(current);
        q++;
      }
      return _.flatten(reducedArray);
    }
    substitutions = void 0;
    switch (pos) {
      case "n":
        substitutions = _.clone(MORPHY_SUBSTITUTIONS.NOUN);
        break;
      case "v":
        substitutions = _.clone(MORPHY_SUBSTITUTIONS.VERB);
        break;
      case "a":
        substitutions = _.clone(MORPHY_SUBSTITUTIONS.ADJECTIVE);
        break;
      default:
        substitutions = [];
    }
    found_exceptions = [];
    exception_morphs = EXCEPTIONS.map(function(elem) {
      return elem.morph;
    });
    index = exception_morphs.indexOf(input_str);
    while (index !== -1) {
      if (EXCEPTIONS[index].pos === pos) {
        base_word = new Word(EXCEPTIONS[index].lemma);
        base_word.part_of_speech = pos;
        found_exceptions.push(base_word);
      }
      index = exception_morphs.indexOf(input_str, index + 1);
    }
    if (found_exceptions.length > 0) {
      return found_exceptions;
    } else {
      if (pos === "n" && input_str.endsWith("ful")) {
        suffix = "ful";
        input_str = input_str.slice(0, input_str.length - suffix.length);
      } else {
        suffix = "";
      }
      return rulesOfDetachment(input_str, substitutions);
    }
  };

  getCorpusSynsets = function(docs) {
    var corpus, vocab, wordArrays;
    if (Array.isArray(docs) === false) {
      docs = Array(docs);
    }
    corpus = new tm.Corpus(docs);
    corpus = corpus.removeInterpunctuation().removeNewlines().toLower().clean().removeWords(tm.STOPWORDS.EN).clean().removeDigits().removeInvalidCharacters();
    console.log('Document pre-processing finished');
    vocab = new Vocabulary();
    wordArrays = corpus.documents.map((function(_this) {
      return function(x) {
        return x.split(" ");
      };
    })(this));
    wordArrays = wordArrays.map((function(_this) {
      return function(arr) {
        var res;
        res = arr.reduce(function(a, b) {
          var existingWord;
          existingWord = a.filter(function(x) {
            return x.string === b;
          });
          if (existingWord.length > 0) {
            existingWord[0].count++;
            return a;
          } else {
            word = {};
            word.string = b;
            word.id = vocab.add(b);
            word.count = 1;
            return a.concat(word);
          }
        }, []);
        return res;
      };
    })(this));
    return {
      wordArrays: wordArrays,
      vocab: vocab
    };
  };

  createDocTree = function(wordArray) {
    var baseWordArray, synsetsArray;
    baseWordArray = wordArray.map((function(_this) {
      return function(x) {
        x.baseWords = morphy(x.string, "n");
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

  module.exports = exports = {
    createDocTree: createDocTree,
    getCorpusSynsets: getCorpusSynsets,
    Word: Word
  };

}).call(this);

//# sourceMappingURL=synsetRepresentation.js.map
