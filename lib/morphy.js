var fs = require('fs');
var _ = require("underscore");
var str = require("./string.js");

var DICTIONARY = JSON.parse(fs.readFileSync("../data/DICTIONARY.json"));

var EXCEPTIONS = JSON.parse(fs.readFileSync("../data/EXCEPTIONS.json"));

var MORPHY_SUBSTITUTIONS = {
  NOUN:
  [{ suffix: 's', ending: ''},
  { suffix: 'ses', ending: 's'},
  { suffix: 'ves', ending: 'f'},
  { suffix: 'xes', ending: 'x'},
  { suffix: 'zes', ending: 'z'},
  { suffix: 'ches', ending: 'ch'},
  { suffix: 'shes', ending: 'sh'},
  { suffix: 'men', ending: 'man'},
  { suffix: 'ies', ending: 'y'}],
  VERB:
  [{ suffix: 's', ending: ''},
  { suffix: 'ies', ending: 'y'},
  { suffix: 'es', ending: 'e'},
  { suffix: 'es', ending: ''},
  { suffix: 'ed', ending: 'e'},
  { suffix: 'ed', ending: ''},
  { suffix: 'ing', ending: 'e'},
  { suffix: 'ing', ending: ''}],
  ADJECTIVE:
  [{ suffix: 'er', ending: ''},
  { suffix: 'est', ending: ''},
  { suffix: 'er', ending: 'e'},
  { suffix: 'est', ending: 'e'}]
};

Word = function(str, pos){
	  this.lemma = str;
	  if (pos){
	    this.part_of_speech = pos;
	  }
};

function morphy(input_str, pos){

		if(!pos){
		  var arr = ["n","v","a","r","s"];
		  var resArray = [];
		  for (var i = 0; i <= 4; i++){
		    resArray.push(morphy(input_str, arr[i]));
		    }
		  var reducedArray = [];
		  for (var q = 0; q < resArray.length; q++){
			  var current = resArray[q];
			  reducedArray.push(current);
		  }
  		return _.flatten(reducedArray);
		}

		var substitutions;
		switch(pos){
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

  function rulesOfDetachment(word, substitutions){
	   var result = [];
     DICTIONARY.filter(function(elem){
       return elem.lemma === word;
     }).forEach(function(elem){
				if (elem.pos === pos){
				  var obj = new Word(elem.lemma);
				  obj.part_of_speech = elem.pos;
			    result.push(obj);
				}
      });
    for (var i = 0; i < substitutions.length; i++){
		  var suffix = substitutions[i].suffix;
		  var new_ending = substitutions[i].ending;

		  if (word.endsWith(suffix) === true){
			  var new_word = word.substring(0, word.length - suffix.length) + new_ending;
			  substitutions.splice(i,1);
			  if (new_word.endsWith("e") && !word.endsWith("e")){
			    substitutions.push({suffix: 'e', ending:''});
			  }
			  var recResult = rulesOfDetachment(new_word, substitutions);
			  Array.isArray(recResult) ? result = result.concat(recResult) : result.push(recResult);
			}
		}
    return result;
	}

	var found_exceptions = [];
	var exception_morphs = EXCEPTIONS.map(function(elem){
		return elem.morph;
	});

	var index = exception_morphs.indexOf(input_str);
	while(index !== -1){
		if(EXCEPTIONS[index].pos === pos){
			var base_word = new Word(EXCEPTIONS[index].lemma);
			base_word.part_of_speech = pos;
			found_exceptions.push(base_word);
		}
	  index = exception_morphs.indexOf(input_str, index + 1);
	}

	if (found_exceptions.length > 0){
	  return found_exceptions;
	}
	else {
	  if(pos === "n" && input_str.endsWith("ful")){
		  suffix = "ful";
		  input_str = input_str.slice(0, input_str.length - suffix.length);
	  } else {
		  suffix = "";
	  }
	  return rulesOfDetachment(input_str, substitutions);
	}
 }

console.log(morphy("king"));
