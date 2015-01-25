PDFDocument = require 'pdfkit'
fs = require 'fs'
util = require 'util'
_ = require 'underscore'
path = require 'path'
require 'plus_arrays'

{
  findCorrelatedSynsets,
  findCorrelatedSynsetsWithId
} = require './findCorrelatedSynsets'

textSummarizer = require 'sum'

fontTitle = (doc) ->
  font_path = path.normalize(__dirname + '/../fonts/Raleway-Thin.ttf')
  doc.font(font_path)

fontBody = (doc) ->
  font_path = path.normalize(__dirname + '/../fonts/DroidSans.ttf')
  doc.font(font_path)

sectionHeader = (doc, text) ->
  doc.addPage()
  doc.fontSize 16
  doc.fillColor 'black'
  fontTitle(doc)
  doc.moveDown(0.5)
  doc.text text,
    width: 410,
    align: 'center'
  doc.moveDown(0.5)

walkTree = (current, parent) ->
  if current.children.length == 1 and parent != null
    child = current.children[0]
    walkTree(child, current)
    if current.words != null
      current_word_lemmas = Object.keys(current.words)
      current_child_lemmas = current.children
      .filter( (c) ->
        return c.words != null
      )
      .map( (c) ->
        return Object.keys(c.words)
      )
      .reduce((a,b) ->
        return a.concat(b)
      ,[])
      if current_word_lemmas.compare(current_child_lemmas) == true
        current.flagged = true
    return

  if current.children.length == 0
    return

  if current.children.length > 1 or parent == null
    current.children.forEach( (child) ->
      walkTree(child, current)
    )
    return

getNonFlaggedChild = (node) ->
  if node.children[0].flagged == true
    return getNonFlaggedChild(node.children[0])
  else
    return node.children[0]

removeFlaggedNodes = (current) ->
  current.children.forEach( (child) ->
    if child.flagged == true and child.parentId != "root"
      insertNode = getNonFlaggedChild(child)
      current.children = current.children.filter((e) ->
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

formD3TreeForId = (tree, synsetid) ->
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
  return tree[synsetid]

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

  correlations = findCorrelatedSynsets(output)
  console.log "Writing PDF file ..."
  correlations.forEach (pair) ->
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

  current_synset = output.tree[options.synsetID]
  title_synset_words = "Report for Synset {" + current_synset.data.words
    .map( (e) -> e.lemma).splice(0,3).join(", ") + "}"
  renderTitlePage(doc, filename, title_synset_words)

  correlations = findCorrelatedSynsetsWithId(output, options.synsetID)
  limit = options.limit || 20
  sorted_correlations = _.sortBy(correlations, (o) -> o.phi)
    .reverse()
    .filter( (o, index) -> return index <= limit )

  sectionHeader(doc, "Synset Co-Occurence")
  fontBody(doc)
  doc.fontSize 10
  doc.text "It co-occurs with the following synsets:"
  sorted_correlations.forEach( (pair) ->
    pair.mutualInfo = pair.mutualInfo.toFixed(2)
    pair.phi        = pair.phi.toFixed(2)
    doc.fontSize 8
    doc.text " #{pair.synset2} | #{pair.phi}"
  )
  synset_words = _.map(current_synset.words, (count, key) ->
    return output.vocab[key]
  )
  synset_words.push("?")

  if options.includeDocs == true
    console.log "Summarize documents..."
    sectionHeader(doc, "Summary of Corpus Documents")
    relevant_subset = output.corpus.filter( (doc, index) ->
      if (doc and current_synset.docs.contains(index) == true)
        return true
      else
        return false
    )

    console.log("Generate summaries...")

    summaries = relevant_subset.map( (doc) ->
      return textSummarizer({
        corpus: doc,
        nSentences: 2,
        emphasise: synset_words
      }).summary)

    filtered_summaries = summaries.filter( (doc) ->
      foundSynset = false
      for word in synset_words
        if doc.indexOf(word) != -1 then foundSynset = true
      return foundSynset
    )

    filtered_summaries.forEach( (txt, i) ->
      txt = txt.replace(/\s+/g, ' ')
      fontBody(doc)
      doc.fontSize 10
      doc.moveDown(0.2)
      doc.text "Document " + i + ":"
      doc.moveDown(0.2)
      doc.fontSize 8
      doc.text txt
    )

  console.log "Writing PDF file ..."
  doc.end()
  return writeStream

writeDocReport = (output, filename, options) ->
  console.log 'Should write DOC Reports'

getLeafs = (tree) ->
  for key, value of tree
    if tree[value.parentId] then delete tree[value.parentId]
  return tree

restrictToAncestor = (tree, ancestorId) ->
  for key, synset of tree
    if not synset.data.ancestorIds?.contains(ancestorId)
      delete tree[key]
  return tree

writeLeafReport = (output, filename, options) ->
  # Create a document
  doc = new PDFDocument()
  # Set up a stream to write to
  writeStream = fs.createWriteStream(filename)
  # Pipe document output to file
  doc.pipe writeStream

  renderTitlePage(doc, filename)
  sectionHeader(doc, "Leaf Synsets")

  fontBody(doc)
  leafs = getLeafs(output.tree)
  console.log(options.root)
  if options.root then leafs = restrictToAncestor(leafs, options.root)

  leafs = _.map(leafs, (value, key) -> value)
  sorted_leafs = leafs.sort( (a, b) ->
    if (a.docCount) > (b.docCount) then return -1
    if (a.docCount) < (b.docCount) then return 1
    return 0
  )
  max_sorted_leafs = sorted_leafs.filter( (val, index) -> index < 50 )
  for synset in max_sorted_leafs
    doc.fontSize 10
    doc.fillColor 'steelblue'
    synset_display_data = synset.data.words
      .map( (e) -> e.lemma )
      .splice(0,3)
      .join(", ") + " (w: #{synset.wordCount}, d: #{synset.docCount}):"
    if options.everything == true
      doc.text synset_display_data,
         link: 'http://localhost:8000/synsets/' + synset.synsetid + ".pdf"
    else
      doc.text synset_display_data
    doc.fillColor 'black'
    doc.fontSize 6
    if options.includeIDs == true then doc.text "ID: " + synset.synsetid
    doc.text synset.data.definition
    if options.docReferences
      doc.text "[appears in document: " + synset.docs.join(", ") + "]"

    if options.includeWords
      doc.text "Words:"
      wordStringArr = []
      wordArr = _.map(synset.words, (count, key) ->
        o = {}
        o.word = output.vocab[key]
        o.count = count
        return o
      ).sort( (a, b) ->
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
      for string in wordStringArr
        doc.text string
  # Finalize PDF file
  doc.end()
  if options.everything == true
    for key, value of output.tree
      options.synsetID = key
      options.includeDocs = true
      synsetWriteStream = writeSynsetReport(
        output,
        "./synsets/" + key + ".pdf",
        options
      )
      synsetWriteStream.on("close", () ->
        console.log("Synset Report " + key + " written")
      )
  return writeStream

writeCorpusReport = (output, filename, options) ->

  # Create a document
  doc = new PDFDocument()

  # Set up a stream to write to
  writeStream = fs.createWriteStream(filename)

  # Pipe document output to file
  doc.pipe writeStream

  renderTitlePage(doc, filename)
  if not options.root
    root = formD3Tree(output.tree)
  else
    root = formD3TreeForId(output.tree, options.root)

  sectionHeader(doc, "Corpus Synset Tree")
  fontBody(doc)
  printSynset = (synset, depth) ->
    doc.fontSize 10
    doc.fillColor 'steelblue'
    concatenated_words = synset.data.words
      .map( (e) -> e.lemma)
      .splice(0,3)
      .join(", ")
    synset_display_data = Array(depth).join("-") +
      " " +
      concatenated_words +
      " (w: #{synset.wordCount}, d: #{synset.docCount}):"

    if options.everything == true
      doc.text synset_display_data,
         link: 'http://localhost:8000/synsets/' + synset.synsetid + ".pdf"
    else
      doc.text synset_display_data

    doc.fillColor 'black'
    doc.fontSize 6
    if options.includeIDs == true then doc.text Array(depth).join(" ") +
      "ID: " +
      synset.synsetid
    doc.text Array(depth).join(" ") + synset.data.definition
    if options.docReferences then doc.text Array(depth).join(" ") +
        "[appears in document: " +
        synset.docs.join(", ") + "]"

    if options.includeWords
      doc.text Array(depth).join(" ") + "Words:"
      wordStringArr = []
      wordArr = _.map(synset.words, (count, key) ->
        o = {}
        o.word = output.vocab[key]
        o.count = count
        return o
      ).sort( (a, b) ->
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

    synset.children.forEach( (synset) -> printSynset(synset, depth + 1))

  root.children.forEach( (synset, index) ->
    depth = 1
    printSynset(synset, depth)
  )


  if options.includeDocs
    sectionHeader(doc, "Corpus Documents")

    output.corpus.forEach( (txt, i) ->
      fontBody(doc)
      doc.fontSize 10
      doc.text "Document " + i + ":"
      doc.fontSize 8
      doc.text txt
    )

  # Finalize PDF file
  doc.end()
  return writeStream

module.exports = exports = {
  writeCorrelationReport: writeCorrelationReport,
  writeCorpusReport: writeCorpusReport,
  writeSynsetReport: writeSynsetReport,
  writeLeafReport: writeLeafReport
}
