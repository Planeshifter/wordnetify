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

prepareWordnetTree = (options) ->
  corpus;
  delim = options.delim
  if options.list
    delim = delim or ";"
    corpus = options.list.split(delim)
    console.log corpus
    createWordNetTree(corpus, options)
  else if (options.input)
    data = fs.readFileSync(options.input)
    mime_type = mime.lookup(options.input)
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
