thresholdDocTree = (tree, threshold) ->
  for id, synset of tree
    do (synset) ->
      if synset.docCount < threshold
        delete tree[id]
  return tree

thresholdWordTree = (tree, threshold) ->
  for id, synset of tree
    do (synset) ->
      if synset.wordCount < threshold
        delete tree[id]
  return tree

module.exports = {thresholdDocTree: thresholdDocTree, thresholdWordTree: thresholdWordTree }
