// String
if (!String.prototype.hasOwnProperty("repeat")){
  String.prototype.repeat = function(num){
    return new Array( num + 1 ).join( this );
  };
}

if (!String.prototype.hasOwnProperty("endsWith")){
  String.prototype.endsWith = function(str){
    var myRegExp = new RegExp(str + "$");
    return myRegExp.test(this);
  };
}
