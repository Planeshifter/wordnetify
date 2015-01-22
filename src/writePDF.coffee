PDFDocument = require 'pdfkit'
fs = require 'fs'
util = require 'util'
_ = require 'underscore'
path = require 'path'
require 'plus_arrays'
{findCorrelatedSynsets, findCorrelatedSynsetsWithId} = require './findCorrelatedSynsets'


fontTitle = (doc) ->
  font_path = path.normalize(__dirname + '/../fonts/Raleway-Medium.ttf')
  doc.font(font_path)

fontBody = (doc) ->
  font_path = path.normalize(__dirname + '/../fonts/DroidSans.ttf')
  doc.font(font_path)

sectionHeader = (doc, text) ->
  doc.addPage
  doc.fontSize 16
  doc.fillColor 'black'
  fontTitle(doc)
  doc.text text,
    width: 410,
    align: 'center'

walkTree = (current, parent) ->
    if current.children.length == 1 and parent != null
      child = current.children[0]
      walkTree(child, current)
      if current.words != null
        current_word_lemmas = Object.keys(current.words)
        current_child_lemmas = current.children.filter((c) =>
           return c.words != null
         ).map( (c) =>
           return Object.keys(c.words)
         ).reduce((a,b) =>
           return a.concat(b)
         ,[])

         if current_word_lemmas.compare(current_child_lemmas) == true
           current.flagged = true
      return;

    if current.children.length == 0
      return;

    if current.children.length > 1 or parent == null
      current.children.forEach((child) =>
        walkTree(child, current);
      )
      return

getNonFlaggedChild = (node) ->
  if node.children[0].flagged == true
    return getNonFlaggedChild(node.children[0])
  else
    return node.children[0]

removeFlaggedNodes = (current) ->
  current.children.forEach( (child) =>
    if child.flagged == true and child.parentId != "root"
      insertNode = getNonFlaggedChild(child)
      current.children = current.children.filter((e) =>
        return e.data.synsetid != child.data.synsetid
      )
      current.children.push(insertNode)
      removeFlaggedNodes(insertNode)
    else
      removeFlaggedNodes(child)
  )


formD3Tree = (tree) ->
  # initialize child arrays
  for key of tree
  	tree[key].children = []
  tree["root"] = {}
  tree["root"].children = []
  for key of tree
    currentNode = tree[key]
    if currentNode.parentId and tree[currentNode.parentId]
    	tree[currentNode.parentId].children.push(currentNode)

  walkTree(tree["root"], null)
  removeFlaggedNodes(tree["root"])
  return tree["root"]

# renders the title page of the guide
renderTitlePage = (doc, filename, type = "") ->
  title = 'Corpus: ' + filename.split(".")[0]
  subtitle = 'Synset Tree Output: ' + type
  date = 'generated on ' + new Date().toDateString()
  doc.y = doc.page.height / 2 - doc.currentLineHeight()
  fontTitle(doc)
  doc.fontSize 20
  doc.text title, align: 'left'
  w = doc.widthOfString(title)
  doc.fontSize 16
  doc.text subtitle,
    align: 'left'
  indent: w - doc.widthOfString(subtitle)
  doc.text date,
    align: 'left'
  indent: w - doc.widthOfString(date)
  doc.addPage()


writeCorrelationReport = (output, filename, options) ->
  # Create a document
  doc = new PDFDocument()
  # Set up a stream to write to
  writeStream = fs.createWriteStream(filename)
  # Pipe document output to file
  doc.pipe writeStream
  renderTitlePage(doc, filename, "Correlation Report")

  correlations = findCorrelatedSynsetsWithId(output)
  console.log "Writing PDF file ..."
  correlations.forEach (pair) =>
    doc.text "#{pair.synset1} | #{pair.synset2} | #{pair.mutualInfo}"
  # Finalize PDF file
  doc.end()
  return writeStream

writeSynsetReport = (output, filename, options) ->
    # Create a document
    doc = new PDFDocument()
    # Set up a stream to write to
    writeStream = fs.createWriteStream(filename)
    # Pipe document output to file
    doc.pipe writeStream
    renderTitlePage(doc, filename, "Report for Synset {" + output.tree[options.synsetID].data.words.map((e)=>e.lemma).splice(0,3).join(", ") + "}")

    correlations = findCorrelatedSynsetsWithId(output, options.synsetID)

    console.log "Writing PDF file ..."

    doc.text "Co-occurs with the following synsets:"
    correlations.forEach (pair) =>
      doc.text " #{pair.synset2} | #{pair.mutualInfo}"

    doc.end()
    return writeStream

writeDocReport = (output, filename, options) ->
  console.log 'Should write DOC Reports'

writeCorpusReport = (output, filename, options) ->
  # Create a document
  doc = new PDFDocument()

  # Set up a stream to write to
  writeStream = fs.createWriteStream(filename)

  # Pipe document output to file
  doc.pipe writeStream

  renderTitlePage(doc, filename)

  root = formD3Tree(output.tree)

  sectionHeader(doc, "Corpus Synset Tree")
  fontBody(doc)
  printSynset = (synset, depth) ->
    doc.fontSize 10
    doc.fillColor 'steelblue'
    if options.everything == true
      doc.text Array(depth).join("-") + " " + synset.data.words.map((e)=>e.lemma).splice(0,3).join(", ") + " (w: #{synset.wordCount}, d: #{synset.docCount}):",
         link: 'http://apple.com/'
    else
        doc.text Array(depth).join("-") + " " + synset.data.words.map((e)=>e.lemma).splice(0,3).join(", ") + " (w: #{synset.wordCount}, d: #{synset.docCount}):",

    doc.fillColor 'black'
    doc.fontSize 6
    if options.includeIDs == true then doc.text Array(depth).join(" ") + "ID: " + synset.synsetid
    doc.text Array(depth).join(" ") + synset.data.definition
    if options.docReferences then doc.text Array(depth).join(" ") + "[appears in document: " + synset.docs.join(", ") + "]"

    if options.includeWords
      doc.text Array(depth).join(" ") + "Words:"
      wordStringArr = []
      wordArr = _.map(synset.words, (count, key) =>
        o = {}
        o.word = output.vocab[key]
        o.count = count
        return o
      ).sort( (a, b) =>
        b.count - a.count
      )
      for obj, i in wordArr
        index = Math.floor(i/12)
        if index < 5
          if not wordStringArr[index]
            wordStringArr[index] = obj.word + "(" + obj.count + "), "
          else
            wordStringArr[index] += obj.word + "(" + obj.count + "), "
        else
          wordStringArr[index] = "..."
          break
      spaces = Array(depth).join(" ")
      for string in wordStringArr
        printString = spaces + string
        doc.text printString

      doc.text spaces,
        paragraphGap: 8

    synset.children.forEach( (synset) => printSynset(synset, depth + 1))

  root.children.forEach( (synset, index) =>
    depth = 1
    printSynset(synset, depth)
  )


  if options.includeDocs
    sectionHeader(doc, "Corpus Documents")

    output.corpus.forEach( (txt, i) =>
      fontBody(doc)
      doc.fontSize 10
      doc.text "Document " + i + ":"
      doc.fontSize 8
      doc.text txt
    )

  # Finalize PDF file
  doc.end()
  return writeStream

module.exports = {
  writeCorrelationReport: writeCorrelationReport,
  writeCorpusReport: writeCorpusReport,
  writeSynsetReport: writeSynsetReport
}
