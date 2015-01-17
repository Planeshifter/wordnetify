program       = require 'commander'
fs            = require 'fs'
csv           = require 'csv'
mime          = require 'mime'
BPromise      = require 'bluebird'
util          = require 'util'
rp            = require 'request-promise'
querystring   = require 'querystring'
child_process = require 'child_process'
ProgressBar   = require 'progress'
heapdump      = require 'heapdump'

{ getCorpusSynsets }            = require "./synsetRepresentation"
{ constructSynsetData }         = require "./constructSynsetData"
pickSynsets                     = require "./pickSynsets"
{ generateCorpusTree, generateWordTree } = require "./treeGenerator"
thresholdTree                   = require "./thresholdTree"
calculateCounts                 = require "./counting"
{ thresholdDocTree, thresholdWordTree } = require "./thresholdTree"
createDocTree                   = require "./createDocTree"
cluster = {}

prepareWordnetTree = (options) ->
  corpus;
  delim = options.delim

  if options.list
    delim = delim or ";"
    corpus = options.list.split(delim)
    cluster.server = child_process.fork(__dirname + '/cluster.js')
    cluster.server.on('message', (m) =>
      console.log('Worker connection established:', m.msg);
      createWordNetTree(corpus, options)
    )
  else if (options.input)
    data = fs.readFileSync(options.input)
    mime_type = mime.lookup(options.input)

    createWordNetTreeCluster = () ->
       console.log 'Number of Documents to analyze: ' + corpus.length
       cluster.server = child_process.fork(__dirname + '/cluster.js')
       cluster.server.on('message', (m) =>
         console.log('Worker connection established:', m.msg);
         createWordNetTree()
       )

    switch mime_type
      when "text/plain"
        delim = delim or "  "
        corpus = String(data).replace(/\r\n?/g, "\n").split(delim).clean("")
        createWordNetTreeCluster()
      when "text/csv"
        csv.parse(String(data), (err, output) =>
          corpus = output.map( (d) => d[0] )
          createWordNetTreeCluster()
        )
      when "application/json"
        corpus = JSON.parse(data)
        createWordNetTreeCluster()

  createWordNetTree = () ->
      wordTreshold = if options.threshold then options.threshold else  1
      {wordArrays, vocab} = getCorpusSynsets(corpus)

      progressCreateDocTree = new ProgressBar('Create document trees [:bar] :percent :etas', { total: wordArrays.length })
      wordArrays = wordArrays.map( (doc) =>
        ret = createDocTree(doc)
        progressCreateDocTree.tick()
        return ret
      )
      progressDisambiguation = new ProgressBar('Synset disambiguation [:bar] :percent :etas', { total: wordArrays.length })
      heapdump.writeSnapshot();
      active_jobs = 0
      fPrunedDocTrees = []
      nJobs = wordArrays.length
      active_index = 0
      nCPUS = require('os').cpus().length
      myInterval = setInterval(() =>
        if active_jobs <= nCPUS
          if active_index >= nJobs
              clearInterval(myInterval)
              processPrunedDocTrees()
          else
            active_jobs++
            doc = wordArrays[active_index]
            postData = {doc : JSON.stringify(doc), index: active_index}
            fRequest = rp.post(
                'http://localhost:8000/getBestSynsets',
                { body: querystring.stringify(postData)})
            fRequest
              .catch( (err) =>
                console.log(err)
              )
              .then( (req) =>
                active_jobs--
                active_index++
                progressDisambiguation.tick()
              )
            fPrunedDocTrees.push fRequest.then(JSON.parse)
      , 100)
      processPrunedDocTrees = () ->
        BPromise.all(fPrunedDocTrees).then( (prunedDocTrees) =>
          cluster.server.kill('SIGTERM')
          outputJSON = ''

          # heapdump.writeSnapshot()

          if options.combine
            corpusTree = generateCorpusTree(prunedDocTrees)
            finalTree = calculateCounts(corpusTree)
            # heapdump.writeSnapshot()
            if options.threshold
              finalTree = thresholdDocTree(finalTree, options.threshold)
            ret = {}
            ret.tree = finalTree
            ret.vocab = vocab.getArray()
            ret.corpus = corpus
            outputJSON = if options.pretty then JSON.stringify(ret, null, 2) else JSON.stringify(ret)
          else
            ret = prunedDocTrees.map( (doc) => generateWordTree(doc) )
                                .map( (doc) => calculateCounts(doc) )
            if options.threshold
              ret = ret.map( (tree) => thresholdWordTree(tree))

            heapdump.writeSnapshot()
            outputJSON = if options.pretty then JSON.stringify(ret, null, 2) else JSON.stringify(ret)

          if options.output
            fs.writeFileSync(options.output, outputJSON)
          else
            console.log(outputJSON)
          return
        ).finally( () =>
          console.log "Job successfully completed."
          process.exit(code=0)
        ).catch( (err) =>
          console.log(err)
          console.log "Job aborted with errors."
          process.exit(code=1)
        )

generatePDF = (options) ->
  file = fs.readFileSync(options.input)
  synsetTree = JSON.parse(file)
  pdfOptions = {}
  pdfOptions.includeDocs = options.includeDocs
  pdfOptions.includeWords = options.includeWords
  pdfOptions.docReferences = options.docReferences
  pdfOptions.synsetId = options.synsetId
  pdfOptions.type = options.type
  writePDF = require "./writePDF"
  writeStream = writePDF(synsetTree, options.output, pdfOptions)
  writeStream
    .on("close", () =>
      console.log "Job successfully completed."
      process.exit(code=0)
    ).on("error", () =>
      console.log "Job aborted with errors."
      process.exit(code=1)
    )

###
Command-Line-Interface:
###

program
  .version('0.2.1')
  .option('-v, --verbose','Print additional logging information')

program
  .command('PDF')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-t,--type <type>', 'Specify type of report: doc, corpus, synset, correlation')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .option('-s,--synsetId [value]', 'Specify synset id [required for synset report]')
  .action(generatePDF)

program
  .command('JSON')
  .description('export synset tree to JSON format')
  .option('-i, --input [value]', 'Load data from disk')
  .option('-l, --list <items>','A list of input texts')
  .option('-o, --output [value]', 'Write results to file')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Merge document trees to form corpus tree')
  .option('-d, --delim [value]','Delimiter to split text into documents')
  .option('-p, --pretty','Pretty print of JSON output')
  .action(prepareWordnetTree)

program
  .parse(process.argv)
