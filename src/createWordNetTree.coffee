program       = require 'commander'
fs            = require 'fs'
csv           = require 'csv'
mime          = require 'mime'
BPromise      = require 'bluebird'
util          = require 'util'
request       = require 'request'
querystring   = require 'querystring'
child_process = require 'child_process'
ProgressBar   = require 'progress'
Parallax      = require 'parallax'
HashTable     = require 'hashtable'

{ getCorpusSynsets }            = require "./synsetRepresentation"
{ generateCorpusTree, generateWordTree } = require "./treeGenerator"
thresholdTree                   = require "./thresholdTree"
calculateCounts                 = require "./counting"
{ thresholdDocTree, thresholdWordTree } = require "./thresholdTree"
createDocTree                   = require "./createDocTree"

createWordNetTree = (corpus, options) ->
  console.log 'Number of Documents to analyze: ' + corpus.length
  corpusHashTable = new HashTable()
  wordTreshold = if options.threshold then options.threshold else  1
  {wordArrays, vocab} = getCorpusSynsets(corpus)
  for doc, index in corpus
    corpusHashTable.put(index, doc)
  corpus = []

  progressCreateDocTree = new ProgressBar('Create document trees [:bar] :percent :etas', { total: wordArrays.length })
  wordArrays = wordArrays.map( (doc) =>
    ret = createDocTree(doc)
    progressCreateDocTree.tick()
    return ret
  )
  parallel = new Parallax(wordArrays,{"seriesWorkers":"lib/seriesWorkers.js"},{CPUs: 4})
  parallel.apply([{namespace: "seriesWorkers", function:"disambiguateDoc"}], (err, res) =>
    processPrunedDocTrees(err, res)
  )
  # progressDisambiguation = new ProgressBar('Synset disambiguation [:bar] :percent :etas', { total: wordArrays.length })

  processPrunedDocTrees = (error, prunedDocTrees) ->
    # prunedDocTrees = prunedDocTrees.map (doc) => JSON.parse(doc)

    outputJSON = ''

    if options.combine
      corpusTree = generateCorpusTree(prunedDocTrees)
      finalTree = calculateCounts(corpusTree)
      if options.threshold
        finalTree = thresholdDocTree(finalTree, options.threshold)
      ret = {}
      ret.tree = finalTree
      ret.vocab = vocab.getArray()

      corpusHashTable.forEach( (key,value) =>
        corpus.push(value)
      )
      ret.corpus = corpus
      outputJSON = if options.pretty then JSON.stringify(ret, null, 2) else JSON.stringify(ret)
    else
      ret = prunedDocTrees.map( (doc) => generateWordTree(doc) )
                          .map( (doc) => calculateCounts(doc) )
      if options.threshold
        ret = ret.map( (tree) => thresholdWordTree(tree))

      outputJSON = if options.pretty then JSON.stringify(ret, null, 2) else JSON.stringify(ret)

    if options.output
      fs.writeFileSync(options.output, outputJSON)
    else
      console.log(outputJSON)
    if(!error)
      console.log "Job successfully completed."
      process.exit(code=0)
    else
      console.log(error)
      console.log "Job aborted with errors."
      process.exit(code=1)

module.exports = exports = createWordNetTree
