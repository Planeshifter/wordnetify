program       = require 'commander'
fs            = require 'fs'
csv           = require 'csv'
mime          = require 'mime'
BPromise      = require 'bluebird'
util          = require 'util'
rp            = require 'request-promise'
request       = require 'request'
querystring   = require 'querystring'
child_process = require 'child_process'
ProgressBar   = require 'progress'
Parallax      = require 'parallax'
# heapdump    = require 'heapdump'
HashTable     = require 'hashtable'

{ getCorpusSynsets }            = require "./synsetRepresentation"
{ constructSynsetData }         = require "./constructSynsetData"
pickSynsets                     = require "./pickSynsets"
{ generateCorpusTree, generateWordTree } = require "./treeGenerator"
thresholdTree                   = require "./thresholdTree"
calculateCounts                 = require "./counting"
{ thresholdDocTree, thresholdWordTree } = require "./thresholdTree"
createDocTree                   = require "./createDocTree"
createWordNetTree               = require "./createWordNetTree"
cluster = {}


prepareInputTexts = (inputTexts, options) ->
  corpus
  delim = options.delim
  delim = delim or ";"
  corpus = inputTexts.split(delim)
  createWordNetTree(corpus, options)

prepareWordnetTree = (inputFile, options) ->
  corpus;
  delim = options.delim
  data = fs.readFileSync(inputFile)
  mime_type = mime.lookup(inputFile)
  switch mime_type
    when "text/plain"
      delim = delim or "  "
      corpus = String(data).replace(/\r\n?/g, "\n").split(delim).clean("")
      createWordNetTree(corpus, options)
    when "text/csv"
      csv.parse(String(data), (err, output) =>
        corpus = output.map( (d) => d[0] )
        createWordNetTree(corpus, options)
      )
    when "application/json"
      corpus = JSON.parse(data)
      createWordNetTree(corpus, options)

generatePDF = (type, options, id) ->
  file = fs.readFileSync(options.input)
  synsetTree = JSON.parse(file)
  pdfOptions = {}
  pdfOptions.includeDocs = options.includeDocs
  pdfOptions.includeWords = options.includeWords
  pdfOptions.docReferences = options.docReferences
  pdfOptions.includeIDs = options.includeIDs
  pdfOptions.type = type
  pdfOptions.synsetID = options.synsetID
  pdfOptions.everything = options.everything
  {writeDocReport, writeCorpusReport, writeSynsetReport, writeCorrelationReport} = require "./writePDF"

  switch type
    when "doc"
      # receive an Array of documents
      writeStream = writeDocReport(synsetTree,  options.output, pdfOptions)
    when "corpus"
      # receive a single object containing three keys:
      #   tree: synset trees
      #   vocab: vocabulary
      #   corpus: original texts
      writeStream = writeCorpusReport(synsetTree, options.output, pdfOptions)
    when "synset"
      writeStream = writeSynsetReport(synsetTree, options.output, pdfOptions)
    when "correlation"
      writeStream = writeCorrelationReport(synsetTree, options.output, pdfOptions)
    else throw new Error("Type of report has to be specified.")

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
  .command('report-corpus')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .option('-s,--includeIDs', 'Include synset IDs')
  .option('-e,--everything', 'Also create synset/doc reports and link them to the corpus report')
  .action( (options) =>
    generatePDF("corpus", options)
  )

program
  .command('report-doc')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-t,--type <type>', 'Specify type of report: doc, corpus, synset, correlation')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .action( (options) =>
    generatePDF("doc", options)
  )

program
  .command('report-synset [synsetID]')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .option('-l,--limit [value]','Maximum displayed number of correlated synsets')
  .action( (synsetID, options) =>
    options.synsetID = synsetID
    generatePDF("synset", options)
  )

program
  .command('report-corr')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-t,--type <type>', 'Specify type of report: doc, corpus, synset, correlation')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .option('-s,--synsetId', 'Display synset IDs')
  .action( (options) =>
    generatePDF("correlation", options)
  )

program
  .command('file <file>')
  .description('convert corpus to synset tree(s)')
  .option('-o, --output [value]', 'Write results to file')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Merge document trees to form corpus tree')
  .option('-d, --delim [value]','Delimiter to split text into documents')
  .option('-p, --pretty','Pretty print of JSON output')
  .action( (inputFile, options) =>
    prepareWordnetTree(inputFile, options)
  )

program
  .command('texts <inputTexts>')
  .description('convert corpus to synset tree(s)')
  .option('-o, --output [value]', 'Write results to file')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Merge document trees to form corpus tree')
  .option('-d, --delim [value]','Delimiter to split text into documents')
  .option('-p, --pretty','Pretty print of JSON output')
  .action( (inputTexts, options) =>
    prepareInputTexts(inputTexts, options)
  )

program
  .parse(process.argv)
