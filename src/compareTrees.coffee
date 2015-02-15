fs = require 'fs'
_  = require 'underscore'

compareTrees = (file1, file2, threshold) ->
  file1 = JSON.parse( fs.readFileSync(file1) )
  file2 = JSON.parse( fs.readFileSync(file2) )
  nDocs1 = file1.corpus.length
  nDocs2 = file2.corpus.length
  treeArr = []

  diff_keys = _.difference(Object.keys(file1.tree), Object.keys(file2.tree))
  common_keys = _.intersection(Object.keys(file1.tree), Object.keys(file2.tree))

  for key in common_keys
    join = {}
    join.a = file1.tree[key]
    join.b = file2.tree[key]
    join.a.doc_percentage = join.a.docCount / nDocs1
    join.a.words_per_doc = join.a.wordCount / nDocs1
    join.b.doc_percentage = join.b.docCount / nDocs2
    join.b.words_per_doc = join.b.wordCount / nDocs1

    ret = {}
    ret.a = {}
    ret.a.words = join.a.data.words.map( (e) -> e.lemma)
    ret.a.doc_percentage = join.a.docCount / nDocs1

    ret.b = {}
    ret.b.words = join.b.data.words.map( (e) -> e.lemma)
    ret.b.doc_percentage = join.b.docCount / nDocs2

    ret.doc_percentage_diff = Math.abs(join.a.doc_percentage - join.b.doc_percentage)
    ret.words_per_doc_diff = Math.abs(join.a.words_per_doc - join.b.words_per_doc)

    if ret.doc_percentage_diff > threshold then treeArr.push(ret)

  treeArr.sort( (a, b) ->
    return b.doc_percentage_diff - a.doc_percentage_diff
  )

  console.log JSON.stringify(treeArr, null, 2)

module.exports = compareTrees
