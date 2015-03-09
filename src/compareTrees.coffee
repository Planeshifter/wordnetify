fs = require 'fs'
_  = require 'underscore'
prettyjson = require 'prettyjson'
normal = require('jStat').jStat.normal
multtest = require 'multtest'

Phi_inv = (p) ->
  return normal.inv(p, 0, 1)

Phi = (x) ->
  return normal.cdf(x, 0, 1)

compareTrees = (file1, file2, options) ->
  file1 = JSON.parse( fs.readFileSync(file1) )
  file2 = JSON.parse( fs.readFileSync(file2) )
  nDocs1 = file1.corpus.length
  nDocs2 = file2.corpus.length
  treeArr = []
  threshold = options.threshold || 0
  alpha = options.alpha || 0.05

  pretty = options.pretty

  console.log threshold
  console.log pretty

  diff_keys = _.difference(Object.keys(file1.tree), Object.keys(file2.tree))
  common_keys = _.intersection(Object.keys(file1.tree), Object.keys(file2.tree))

  # FDR correction:
  pvalues = []

  for key in common_keys
    join = {}
    join.a = file1.tree[key]
    join.b = file2.tree[key]
    join.a.doc_percentage = join.a.docCount / nDocs1
    join.a.words_per_doc = join.a.wordCount / nDocs1
    join.b.doc_percentage = join.b.docCount / nDocs2
    join.b.words_per_doc = join.b.wordCount / nDocs1

    ret = {}
    ret.synsetid = join.a.synsetid
    ret.ancestorIds = join.a.data.ancestorIds
    ret.words = join.a.data.words.map( (e) -> e.lemma)
    ret.a = {}
    ret.a.doc_percentage = join.a.docCount / nDocs1

    ret.b = {}
    ret.b.doc_percentage = join.b.docCount / nDocs2

    ret.doc_percentage_diff = join.a.doc_percentage - join.b.doc_percentage
    ret.words_per_doc_diff = join.a.words_per_doc - join.b.words_per_doc

    if Math.abs(ret.doc_percentage_diff) > threshold then treeArr.push(ret)

  for elem in treeArr

    elem.delta_variance =
    ( elem.a.doc_percentage * (1 - elem.a.doc_percentage) ) /
    nDocs1 +  ( elem.b.doc_percentage * (1 - elem.b.doc_percentage) ) /
    nDocs2

    tStat = elem.doc_percentage_diff / ( Math.sqrt(elem.delta_variance) )
    pvalue = ( 1 - Phi(tStat) ) * 2
    pvalues.push(elem.pvalue)


  pvalues = multtest.bY(pvalues, common_keys.length)
  alpha = multtest.adjustSignificanceLevel(pvalues, alpha)

  for elem in treeArr
    elem.doc_percentage_diff_CI =
    [
      elem.doc_percentage_diff - Math.sqrt(elem.delta_variance) *
      Phi_inv(1-alpha/2),
      elem.doc_percentage_diff + Math.sqrt(elem.delta_variance) *
      Phi_inv(1-alpha/2)
    ]

  treeArr.sort( (a, b) ->
    return b.doc_percentage_diff - a.doc_percentage_diff
  )

  treeArr = treeArr.filter( (ans) ->
    hasChild = treeArr.some( (child) ->
      child.ancestorIds.contains(ans.synsetid)
    )
    return not hasChild
  )

  if pretty
    console.log prettyjson.render treeArr, {
      keysColor: 'cyan',
      dashColor: 'magenta',
      stringColor: 'white'
    }
  else console.log JSON.stringify( treeArr, null, 2 )

module.exports = compareTrees
