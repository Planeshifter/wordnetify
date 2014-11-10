var tm = require("text-miner"); // utilities for working with text documents
var BPromise = require("bluebird");
var _ = require("underscore");
var util = require("util");
var logger = require("./logger.js");
var morphy = require("./morphy.js");
var memoize = require("./memoize.js");
var Word = require("./Word.js");

var fs = require('fs');
var SYNSETS_JSON = fs.readFileSync(__dirname + '/../data/SYNSETS.json');
WORDNETIFY_SYNSETS_TREE = JSON.parse(SYNSETS_JSON);

function IdsToHypernyms(id){
  return WORDNETIFY_SYNSETS_TREE[id];
}

for (var key in WORDNETIFY_SYNSETS_TREE) {
    if (WORDNETIFY_SYNSETS_TREE.hasOwnProperty(key)) {
        var synset = WORDNETIFY_SYNSETS_TREE[key];
        synset.hypernym = synset.hypernym.map(IdsToHypernyms);
    }
}

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
    logger.log("info", "This is the array of word arrays", {wordArrays: wordArrays});
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
    logger.log("info","This is the array of unique word arrays", {uniqueWordArrays: wordArrays});

    var res = wordArrays.map(function(arr){
      return createDocTree(arr);
    });

    logger.log("info","These are the doc synset Trees",{docTrees:res});
  
    return res;
  }; /* end definition getCorpusSynsets */


  // Helper Functions

  /*
  @wordArray: array of word objects for the doc in question
  */
  function createDocTree(wordArray){

    var baseWordArray = wordArray.map(function(x){
      x.baseWords = morphy(x.string);
      logger.log("info","Morphy base words",{x:x});
      return x;
    });

    var synsetsArray = baseWordArray.map(function(w){
    if (!_.isEmpty(w.baseWords)){
      var bw = new Word(w.baseWords[0].lemma, "n");
      w.synsets = getWordSynsets(bw);
      return w;
    } else {
      w.synsets = null;
      return w;
    }
    });
  //  console.log("SYNSETS ARRAY:")
  //  console.log(util.inspect(synsetsArray, null,4))
    return synsetsArray;
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
    return word.getSynsets();
  });
