
/*
Adapted from:
* memoize.js
* by @philogb and @addyosmani
* with further optimizations by @mathias
* and @DmitryBaranovsk
* perf tests: http://bit.ly/q3zpG3
* Released under an MIT license.
 */

(function() {
  var memoize;

  module.exports = memoize = function(fn) {
    return function() {
      var args, currentArg, hash, i;
      args = Array.prototype.slice.call(arguments);
      hash = "";
      i = args.length;
      currentArg = null;
      while (i--) {
        currentArg = args[i];
        hash += (currentArg === Object(currentArg) ? JSON.stringify(currentArg) : currentArg);
        fn.memoize || (fn.memoize = {});
      }
      if (hash in fn.memoize) {
        return fn.memoize[hash];
      } else {
        return fn.memoize[hash] = fn.apply(this, args);
      }
    };
  };

}).call(this);

//# sourceMappingURL=memoize.js.map
