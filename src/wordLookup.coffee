fs = require 'fs'

SYNSETS_JSON = fs.readFileSync(__dirname + '/../data/SYNSETS.json')
WORDNETIFY_SYNSETS_TREE = JSON.parse(SYNSETS_JSON)

WORDNETIFY_WORD_LOOKUP = {}

for id, synset of WORDNETIFY_SYNSETS_TREE
  synset.words.map( (w) -> w.lemma).forEach( (w) ->
    if not WORDNETIFY_WORD_LOOKUP.hasOwnProperty(w)
      WORDNETIFY_WORD_LOOKUP[w] = [id]
    else
      console.log w
      WORDNETIFY_WORD_LOOKUP[w].push(id)
  )

fs.writeFileSync('LOOKUP.json', JSON.stringify(WORDNETIFY_WORD_LOOKUP))
