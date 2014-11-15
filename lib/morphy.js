(function() {
  var DICTIONARY, EXCEPTIONS, MORPHY_SUBSTITUTIONS, fs, morphy, str, _;

  fs = require('fs');

  _ = require('underscore');

  str = require('./String');

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
    var arr, base_word, current, exception_morphs, found_exceptions, i, index, q, reducedArray, resArray, rulesOfDetachment, substitutions, suffix;
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

  module.exports = morphy;

}).call(this);

//# sourceMappingURL=morphy.js.map
