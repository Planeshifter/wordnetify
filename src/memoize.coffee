###
Adapted from:
* memoize.js
* by @philogb and @addyosmani
* with further optimizations by @mathias
* and @DmitryBaranovsk
* perf tests: http://bit.ly/q3zpG3
* Released under an MIT license.
###

module.exports = memoize = (fn) ->
  ->
    args = Array::slice.call(arguments)
    hash = ""
    i = args.length
    currentArg = null
    while i--
      currentArg = args[i]
      hash += (if (currentArg is Object(currentArg)) then JSON.stringify(currentArg) else currentArg)
      fn.memoize or (fn.memoize = {})
    (if (hash of fn.memoize) then fn.memoize[hash] else fn.memoize[hash] = fn.apply(this, args))
