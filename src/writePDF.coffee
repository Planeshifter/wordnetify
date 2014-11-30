PDFDocument = require 'pdfkit'
fs = require 'fs'
util = require 'util'

writePDF = (output, filename) ->
  if (Array.isArray(output))
    # receive an Array of documents
    return writeDocPdfReport(output, filename)
  else
    # receive a single object containing two keys:
    #   tree: synset trees
    #   corpus: original texts
    return writeCorpusPdfReport(output, filename)

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
      return;

    if current.children.length == 0
      return;

    if current.children.length > 1 or parent == null
      current.children.forEach((child) =>
        walkTree(child, current);
      )
      return

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

writeDocPdfReport = (output, filename) ->
  console.log 'Should write DOC Reports'

writeCorpusPdfReport = (output, filename) ->
  # Create a document
  doc = new PDFDocument()

  # Set up a stream to write to
  writeStream = fs.createWriteStream(filename)

  # Pipe document output to file
  doc.pipe writeStream

  renderTitlePage(doc, filename)

  root = formD3Tree(output.tree)

  printSynset = (synset, depth) ->
    doc.fontSize 12
    doc.fillColor 'steelblue'
    doc.text synset.data.words.map((e)=>e.lemma).join(", ") + " (#{synset.wordCount}):"
    doc.fillColor 'black'
    doc.fontSize 6
    doc.text  synset.data.definition
    doc.moveDown 1
    doc.text "Number of Documents: #{synset.docCount}"
    doc.text "[appears in document: " + synset.docs.join(", ") + "]"
    doc.text "Words:"

    wordString = ""
    for word, count of synset.words
      wordString += word + "(" + count + "), "

    doc.text wordString,
      paragraphGap: 8

    synset.children.forEach( (synset) => printSynset(synset, depth + 1))

  root.children.forEach( (synset, index) =>
    depth = 1
    printSynset(synset, depth)
  )

  doc.addPage
  doc.fontSize 16
  doc.fillColor 'black'
  doc.text 'Corpus Documents',
    width: 410,
    align: 'center'

  output.corpus.forEach( (txt, i) =>
    doc.font('Times-Roman')
    doc.fontSize 14
    doc.text "Document " + i + ":"
    doc.fontSize 10
    doc.text txt
  )

  # Finalize PDF file
  doc.end()
  return writeStream

module.exports = writePDF
