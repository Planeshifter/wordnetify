(function() {
  var arr, fs, logger, pickSynsets, _;

  _ = require("underscore");

  arr = require("./Array.js");

  logger = require("./logger");

  fs = require("fs");

  pickSynsets = function(doc) {
    var chosen, dists, flaggedRemoval, i, index, index2, maxScore, scores, similarities, synset, word, word2, _i, _j, _k, _l, _len, _len1, _len2, _len3, _m;
    for (index = _i = 0, _len = doc.length; _i < _len; index = ++_i) {
      word = doc[index];
      scores = [];
      for (_j = 0, _len1 = word.length; _j < _len1; _j++) {
        synset = word[_j];
        similarities = [];
        for (index2 = _k = 0, _len2 = doc.length; _k < _len2; index2 = ++_k) {
          word2 = doc[index2];
          if (index !== index2) {
            dists = word2.map((function(_this) {
              return function(synset2) {
                return 0;
              };
            })(this));
            similarities.push(dists.max());
          }
        }
        synset.score = similarities.sum();
        scores.push(synset.score);
      }
      maxScore = scores.max();
      logger.log("info", "Score Array", {
        scores: scores,
        maxScore: maxScore
      });
      chosen = false;
      flaggedRemoval = [];
      for (index = _l = 0, _len3 = word.length; _l < _len3; index = ++_l) {
        synset = word[index];
        if (synset.score !== maxScore || chosen === true) {
          flaggedRemoval.push(index);
        } else {
          chosen = true;
        }
      }
      for (_m = flaggedRemoval.length - 1; _m >= 0; _m += -1) {
        i = flaggedRemoval[_m];
        word.splice(i, 1);
      }
    }
    return doc;
  };

  module.exports = pickSynsets;

}).call(this);
