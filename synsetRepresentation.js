var tm = require("text-miner"); // utilities for working with text documents
var BPromise = require("bluebird");
var _ = require("underscore");
var util = require("util");
var memoize = require("./memoize.js");
var logger = require("./logger.js");

/*
This function takes a corpus of documents and transforms it to an array of promises containing wordNet synset objects.
@docs: array of strings

Value:
[ { string: 'oranges',
    count: 2,
    baseWords: [ [Object], [Object] ],
    synsets: [ [Object], [Object], [Object], [Object], [Object], [Object] ] },
  { string: 'lemons',
    count: 1,
    baseWords: [ [Object] ],
    synsets: [ [Object], [Object], [Object], [Object], [Object] ] }
*/

module.exports = function getCorpusSynsets(docs){

    if (Array.isArray(docs) === false){
      docs = Array(docs);
    }

    var corpus = new tm.Corpus(docs);
    corpus = corpus
        .removeInterpunctuation()
        .removeNewlines()
        .toLower()
        .clean()
        .removeWords(tm.STOPWORDS.EN)
        .clean();

    var wordArrays = corpus.documents.map(function(x){ return x.split(" "); });
    /*
    takes word arrays and maps them to arrays objects containing unique words plus counter, e.g.
    [ [ 'happy' ], [ 'oranges', 'lemons', 'and', 'oranges' ] ]
     =>
    [ [ { string: 'happy', count: 1 } ],
      [ { string: 'oranges', count: 2 },
      { string: 'lemons', count: 1 },
      {sttring: 'and', count: 1 } ]
    ]
    */
    wordArrays = wordArrays.map(function(arr){
      return arr.reduce(function(a,b){
        var existingWord = a.filter(function(x){ return x.string === b; });
        if(existingWord.length > 0){
          existingWord[0].count++;
          return a;
        } else {
          var word = {};
          word.string = b;
          word.count = 1;
          return a.concat(word);
        }
      }, []);
    });
    var res = wordArrays.map(function(arr){
      return createDocTree(arr);
    });
    return BPromise.all(res);

  }; /* end definition getCorpusSynsets */


  // Helper Functions

  /*
  @wordArray: array of word objects for the doc in question
  */
  function createDocTree(wordArray){

    var baseWordArrayPROM = wordArray.map(function(x){
      x.baseWords = wn.morphy(x.string);
      return BPromise.props(x);
    });

    var synsetsArrayPROM = BPromise.all(baseWordArrayPROM)
      .then(function(arr){
        var ret = arr.map(function(w){
        if (!_.isEmpty(w.baseWords)){
          var bw = new wn.Word(w.baseWords[0].lemma,"n");
          w.synsets = getWordSynsets(bw);
          return BPromise.props(w);
        } else {
          w.synsets = null;
          return w;
        }
        });
        return BPromise.all(ret);
      });

    return synsetsArrayPROM;
  }

  /*
  @word: wordNet word object, e.g. { lemma: 'happy', part_of_speech: 'a' }
  returns an array of synsets with their hypernyms, like
 { synsetid: 112729053,
    words: [ [Object], [Object] ],
    definition: 'any citrus tree bearing oranges',
    pos: 'n',
    lexdomain: 'noun.plant',
    hypernym: [ [Object] ] },
  */
  var getWordSynsets = memoize(function(word){
    var ret = word.getSynsets().map(function(s){
      s.hypernym = s.getHypernymsTree();
      return BPromise.props(s);
    });
    return BPromise.all(ret);
  });
