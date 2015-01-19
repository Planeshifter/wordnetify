_ = require 'underscore'
fs = require 'fs'
util = require 'util'
HashTable = require 'hashtable'

SYNSETS_JSON = fs.readFileSync(__dirname + '/../data/SYNSETS.json')
WORDNETIFY_SYNSETS_TREE = JSON.parse(SYNSETS_JSON)

BROWN_JSON = fs.readFileSync(__dirname + '/../data/BROWN.json')
BROWN = JSON.parse(BROWN_JSON);

IdsToHypernyms = (id) -> WORDNETIFY_SYNSETS_TREE[id]

getAncestorIds = (node) ->
  ret = []
  current_node = node
  while (current_node.hypernym.length > 0)
    ret.push(current_node.hypernym[0].synsetid)
    current_node = current_node.hypernym[0]
  return ret

for key, synset of WORDNETIFY_SYNSETS_TREE
    if WORDNETIFY_SYNSETS_TREE.hasOwnProperty(key)
      synset.tagCount = BROWN[key]
      synset.hypernym = synset.hypernym.map IdsToHypernyms

WORDNETIFY_SYNSETS_TREE_HASH_TABLE = new HashTable()

for key, synset of WORDNETIFY_SYNSETS_TREE
    if WORDNETIFY_SYNSETS_TREE.hasOwnProperty(key)
      synset.ancestorIds = getAncestorIds(synset)
      WORDNETIFY_SYNSETS_TREE_HASH_TABLE.put(key, synset)

module.exports = {WORDNETIFY_SYNSETS_TREE_HASH_TABLE: WORDNETIFY_SYNSETS_TREE_HASH_TABLE, BROWN: BROWN}
