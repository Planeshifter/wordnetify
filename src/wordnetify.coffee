# load modules
program       = require 'commander'
fs            = require 'fs'
fse           = require 'fs-extra'
os            = require 'os'
csv           = require 'csv'
mime          = require 'mime'
BPromise      = require 'bluebird'
util          = require 'util'
rp            = require 'request-promise'
request       = require 'request'
querystring   = require 'querystring'
child_process = require 'child_process'
ProgressBar   = require 'progress'
# heapdump    = require 'heapdump'
HashTable     = require 'hashtable'
hasProperties = require 'validate.io-properties'

# load script files
{ getCorpusSynsets }            = require "./synsetRepresentation"
{ constructSynsetData }         = require "./constructSynsetData"
pickSynsets                     = require "./pickSynsets"
{ generateCorpusTree, generateWordTree } = require "./treeGenerator"
thresholdTree                   = require "./thresholdTree"
calculateCounts                 = require "./counting"
{ thresholdDocTree, thresholdWordTree } = require "./thresholdTree"
createDocTree                   = require "./createDocTree"
createWordNetTree               = require "./createWordNetTree"
trainDisambiguation             = require "./trainDisambiguation"
calculateWordNetCoverage        = require "./calculateWordNetCoverage"
compareTrees                    = require "./compareTrees"
cluster = {}

isWordnetifyOutput = (input) ->
  ret = hasProperties(input, ["tree","vocab","corpus","meta"]) and
  typeof input.tree == "object" and
  Array.isArray( input.corpus ) == true and
  typeof input.vocab == "object"
  return ret

prepareInputTexts = (inputTexts, options) ->
  corpus
  meta
  delim = options.delim
  delim = delim or ";"
  corpus = inputTexts.split(delim)
  if options.meta
    meta = JSON.parse( fs.readFileSync(options.meta) )
  else
    meta = null

  createWordNetTree(corpus, meta, options)

prepareInputFile = (inputFile, options, fun) ->
  corpus
  meta
  delim = options.delim
  data = fs.readFileSync(inputFile)

  if options.meta
    meta = JSON.parse( fs.readFileSync(options.meta) )
  else
    meta = null

  mime_type = mime.lookup(inputFile)
  switch mime_type
    when "text/plain"
      delim = delim or "  "
      corpus = String(data).replace(/\r\n?/g, "\n").split(delim).clean("")
      fun(corpus, meta, options)
    when "text/csv"
      csv.parse(String(data), (err, output) ->
        corpus = output.map( (d) -> d[0] )
        fun(corpus, null, options)
      )
    when "application/json"
      corpus = JSON.parse(data)
      fun(corpus, meta, options)

generatePDF = (type, options, id) ->
  file = fs.readFileSync(options.input)
  synsetTree = JSON.parse(file)

  if isWordnetifyOutput(synsetTree) is false
    throw new TypeError "Not a valid Wordnetify input file!"

  pdfOptions = {}
  pdfOptions.alpha = options.alpha || 0.05
  pdfOptions.includeDocs = options.includeDocs
  pdfOptions.includeWords = options.includeWords
  pdfOptions.docReferences = options.docReferences
  pdfOptions.includeIDs = options.includeIDs
  pdfOptions.type = type
  pdfOptions.root = options.root
  pdfOptions.synsetID = options.synsetID
  pdfOptions.everything = options.everything
  pdfOptions.maximum = options.maximum
  pdfOptions.threshold = options.threshold
  {
    writeDocReport,
    writeCorpusReport,
    writeSynsetReport,
    writeCorrelationReport,
    writeLeafReport
  } = require "./writePDF"

  # receive a single object synsetTree containing three keys:
  #   tree: synset trees
  #   vocab: vocabulary
  #   corpus: original texts
  switch type
    when "doc"
      # receive an Array of documents
      writeStream = writeDocReport(synsetTree,  options.output, pdfOptions)
    when "corpus"
      # create all synset reports if --everything is supplied
      if options.everything == true
        for key, value of synsetTree.tree
          options.synsetID = key
          options.includeDocs = false
          synsetWriteStream = writeSynsetReport(
            synsetTree,
            "./synsets/" + key + ".pdf",
            options
          )
          synsetWriteStream.on("close", () ->
            console.log("Synset Report " + key + " written")
          )
      writeStream = writeCorpusReport(synsetTree, options.output, pdfOptions)
    when "leafs"
      writeStream = writeLeafReport(synsetTree, options.output, pdfOptions)
    when "synset"
      pdfOptions.correlation = options.correlation
      writeStream = writeSynsetReport(synsetTree, options.output, pdfOptions)
    when "correlation"
      writeStream = writeCorrelationReport(
        synsetTree,
        options.output,
        pdfOptions
      )
    else throw new Error("Type of report has to be specified.")

  writeStream
    .on("close", () ->
      console.log "Job successfully completed."
      switch  os.platform()
        when "darwin" then child_process.exec("open " + options.output)
        when "linux" then child_process.exec("xdg-open " + options.output)
        when "win32" then child_process.exec("start '' /max " + options.output)
      process.exit(code=0)
    )
    .on("error", () ->
      console.log "Job aborted with errors."
      process.exit(code=1)
    )

doHardReset = () ->
  originalFile = __dirname + '/../data/BROWN.json'
  tagcountFile =  __dirname + '/../data/TAGCOUNTS.json'
  fse.copy originalFile, tagcountFile, (err) ->
    console.log if err then err else "Synset counts reset to Brown corpus."

  performance = {
    "correct": 0 ,
    "incorrect": 0,
    "total": 0
  }
  perfStringified = JSON.stringify performance
  fs.writeFileSync __dirname + '/../config/performance.json', perfStringified
  console.log "Disambiguation performance metrics reset."

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
  .option('-t,--threshold [value]', 'Threshold synsets')
  .option('--root [value]', "root synset")
  .option('-e,--everything',
    'Also create synset/doc reports and link them to the corpus report'
  )
  .action( (options) ->
    generatePDF("corpus", options)
  )

program
  .command('report-leafs')
  .description('generate pdf report for synset leafs')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .option('-s,--includeIDs', 'Include synset IDs')
  .option('-t,--threshold [value]', 'Threshold synsets')
  .option('-m,--maximum [value]','Maximum synsets to display')
  .option('--root [value]', "root synset")
  .option('-e,--everything',
    'Also create synset/doc reports and link them to the corpus report'
  )
  .action( (options) ->
    generatePDF("leafs", options)
  )

program
  .command('report-doc')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .action( (options) ->
    generatePDF("doc", options)
  )

program
  .command('report-synset <synsetID> [otherIDs...]')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]',
  'File name of generated PDF (or prefix if multiple synsets supplied)')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .option('-l,--limit [value]','Maximum displayed number of correlated synsets')
  .option('-c,--correlation[value]',
    'Measure of correlation; possible values are Phi, mutual information')
  .option('-a,--alpha [value]', 'Significance level alpha')
  .action( (synsetID, otherIDs, options) ->
    options.synsetID = synsetID
    filePrefix = options.output
    if otherIDs then options.output = filePrefix + "_" + synsetID
    generatePDF("synset", options)
    if otherIDs
      otherIDs.forEach( (id) ->
        if id
          options.synsetID = id
          options.output = filePrefix + "_" + id
          generatePDF("synset", options)
      )
  )

program
  .command('report-corr')
  .description('generate pdf report')
  .option('-i, --input [value]', 'Input JSON synset tree file')
  .option('-o, --output [value]', 'File name of generated PDF')
  .option('-d, --includeDocs', 'Append documents to report')
  .option('-r,--docReferences', 'Include document IDs for each synset')
  .option('-w,--includeWords', 'Include words for each synset')
  .option('-s,--synsetId', 'Display synset IDs')
  .action( (options) ->
    generatePDF("correlation", options)
  )

program
  .command('file <file>')
  .description('Convert corpus to synset tree(s)')
  .option('-m, --meta [value]', 'File holding meta information on docs')
  .option('-o, --output [value]', 'Write results to file')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Merge document trees to form corpus tree')
  .option('-d, --delim [value]','Delimiter to split text into documents')
  .option('-p, --pretty','Pretty print of JSON output')
  .option('-n, --numCPUs [value]','Number of CPUs used')
  .action( (inputFile, options) ->
    prepareInputFile(inputFile, options, createWordNetTree)
  )

program
  .command('texts <inputTexts>')
  .description('convert corpus to synset tree(s)')
  .option('-m, --meta [value]', 'File holding meta information on docs')
  .option('-o, --output [value]', 'Write results to file')
  .option('-t, --threshold <n>', 'Threshold for Tree Nodes', parseInt)
  .option('-c, --combine','Merge document trees to form corpus tree')
  .option('-d, --delim [value]','Delimiter to split text into documents')
  .option('-p, --pretty','Pretty print of JSON output')
  .option('-n, --numCPUs [value]','Number of CPUs used')
  .action( (inputTexts, options) ->
    prepareInputTexts(inputTexts, options)
  )

program
  .command('train <input>')
  .description('train the disambiguation algorithm')
  .action( (inputFile, options) ->
    prepareInputFile(inputFile, options, trainDisambiguation)
  )

program
  .command('coverage <input>')
  .description('calculate synset coverage of generated tree')
  .action( (inputFile, options) ->
    calculateWordNetCoverage(inputFile, options)
  )

program
  .command('reset')
  .description('restore original Brown corpus tag counts and remove' +
  'performance stats')
  .action( () ->
    doHardReset()
  )

program
  .command('compare <file1> <file2>')
  .description('compare two synset trees')
  .option('-t, --threshold <percentage>','Threshold for synset difference')
  .option('-p, --pretty','make output pretty (does not return JSON anymore)')
  .option('-a,--alpha [value]', 'Significance level alpha')
  .action( (file1, file2, options) ->
    compareTrees(file1, file2, options)
  )

program
  .parse(process.argv)
