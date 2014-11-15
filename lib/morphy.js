(function() {
  var DICTIONARY, EXCEPTIONS, MORPHY_SUBSTITUTIONS, Word, fs, morphy, str, _;

  fs = require('fs');

  _ = require('underscore');

  str = require('./String.js');

  Word = require('./Word');

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
    resultSet;
    var arr, base_word, elem, exception_morphs, found_exceptions, index, reducedArray, res, resArray, resultSet, rulesOfDetachment, substitutions, suffix, _i, _j, _len, _len1;
    if (!pos) {
      arr = ["n", "v", "a", "r", "s"];
      resArray = [];
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        elem = arr[_i];
        resArray.push(morphy(input_str, elem));
      }
      reducedArray = [];
      for (_j = 0, _len1 = resArray.length; _j < _len1; _j++) {
        res = resArray[_j];
        reducedArray.push(res);
      }
      resultSet = _.flatten(reducedArray);
    } else {
      substitutions;
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
      rulesOfDetachment = function(word, substitutions) {
        var index, new_ending, new_word, recResult, result, sub, suffix, _k, _len2;
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
        for (index = _k = 0, _len2 = substitutions.length; _k < _len2; index = ++_k) {
          sub = substitutions[index];
          suffix = sub.suffix;
          new_ending = sub.ending;
          if (word.endsWith(suffix) === true) {
            new_word = word.substring(0, word.length - suffix.length) + new_ending;
            substitutions.splice(index, 1);
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
          return result;
        }
      };
      found_exceptions = [];
      exception_morphs = EXCEPTIONS.map((function(_this) {
        return function(elem) {
          return elem.morph;
        };
      })(this));
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
        resultSet = found_exceptions;
      } else {
        if (pos === "n" && input_str.endsWith("ful")) {
          suffix = "ful";
          input_str = input_str.slice(0, input_str.length - suffix.length);
        } else {
          suffix = "";
        }
        resultSet = rulesOfDetachment(input_str, substitutions);
      }
    }
    return resultSet;
  };

  module.exports = morphy;

}).call(this);
