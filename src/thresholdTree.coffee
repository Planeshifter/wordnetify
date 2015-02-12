###
after word and doc counts are calculated,
remove all synsets which appear of @tree which
appear in less than @threshold of the documents
or words, depending on whether thresholdDocTree or
thresholdWordTree is called
###

thresholdDocTree = (tree, threshold) ->
  for id, synset of tree
    do (synset) ->
      if synset.docCount < threshold
        tree[synset.parentId]?.isCandidate = true
        delete tree[id]
  return tree

thresholdWordTree = (tree, threshold) ->
  for id, synset of tree
    do (synset) ->
      if synset.wordCount < threshold
        tree[synset.parentId]?.isCandidate = true
        delete tree[id]
  return tree

module.exports = exports = {
  thresholdDocTree: thresholdDocTree,
  thresholdWordTree: thresholdWordTree
}
