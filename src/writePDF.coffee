PDFDocument = require 'pdfkit'
fs = require 'fs'
util = require 'util'
_ = require 'underscore'
require 'plus_arrays'

writePDF = (output, filename, options = {}) ->
  if (Array.isArray(output))
    # receive an Array of documents
    return writeDocPdfReport(output, filename, options)
  else
    # receive a single object containing three keys:
    #   tree: synset trees
    #   vocab: vocabulary
    #   corpus: original texts
    return writeCorpusPdfReport(output, filename, options)

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
renderTitlePage = (doc, filename) ->
  title = 'Corpus: ' + filename.split(".")[0]
  subtitle = 'Synset Tree Output'
  date = 'generated on ' + new Date().toDateString()
  doc.y = doc.page.height / 2 - doc.currentLineHeight()
  doc.font 'Helvetica'
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

writeDocPdfReport = (output, filename, options) ->
  console.log 'Should write DOC Reports'

writeCorpusPdfReport = (output, filename, options) ->
  # Create a document
  doc = new PDFDocument()

  # Set up a stream to write to
  writeStream = fs.createWriteStream(filename)

  # Pipe document output to file
  doc.pipe writeStream

  renderTitlePage(doc, filename)

  root = formD3Tree(output.tree)

  printSynset = (synset, depth) ->
    doc.fontSize 10
    doc.fillColor 'steelblue'
    doc.text Array(depth).join("-") + " " + synset.data.words.map((e)=>e.lemma).splice(0,3).join(", ") + " (w: #{synset.wordCount}, d: #{synset.docCount}):"
    doc.fillColor 'black'
    doc.fontSize 6
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
    doc.addPage
    doc.fontSize 14
    doc.fillColor 'black'
    doc.text 'Corpus Documents',
      width: 410,
      align: 'center'

    output.corpus.forEach( (txt, i) =>
      doc.font('Times-Roman')
      doc.fontSize 12
      doc.text "Document " + i + ":"
      doc.fontSize 10
      doc.text txt
    )

  # Finalize PDF file
  doc.end()
  return writeStream

module.exports = writePDF
