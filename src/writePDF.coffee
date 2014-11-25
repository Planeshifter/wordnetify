PDFDocument = require 'pdfkit'
fs = require 'fs'

# Create a document
doc = new PDFDocument

# Pipe it's output somewhere, like to a file or HTTP response
# See below for browser usage
doc.pipe fs.createWriteStream('output.pdf')

file = fs.readFileSync("fruits.json")
output = JSON.parse(file)

leafs = []
for key, value of output.tree
  if value.isCandidate == true then leafs.push(value)

console.log leafs

doc.fontSize 16
doc.text 'Synsets',
  width: 410,
  align: 'center'

leafs.forEach( (synset, i) =>
  doc.fontSize 12
  doc.fillColor 'steelblue'
  doc.text "Leaf: " + synset.data.words.map((e)=>e.lemma).join(", ")
  doc.fillColor 'black'
  doc.fontSize 8
  doc.text "Definition: #{synset.data.definition}"
  doc.text "Number of Documents: #{synset.docCount} [appears in document: " + synset.docs.join(", ") + "]"
  doc.text "Number of Words: #{synset.wordCount}"

  doc.fontSize 6
  doc.text "Words:"

  wordString = ""
  console.log synset
  for word, count of synset.words
    console.log word
    wordString += word + "(" + count + "), "

  doc.text wordString,
    paragraphGap: 8

  doc.fontSize 10
  doc.text 'Hypernyms:'
  ancestors = []

  current = synset
  while current and current.parentId != "root"
    ancestors.push(current.parentId)
    console.log current.parentId
    current = output.tree[current.parentId]

  console.log ancestors
  ancestors.forEach( (id, i) =>
    hypernym = output.tree[id]
    doc.fontSize 8
    doc.fillColor 'steelblue'
    doc.text Array(i+1).join("  ") + hypernym.data.words.map((e)=>e.lemma).join(", ")
    doc.fillColor 'black'
    doc.text Array(i+1).join("  ") + "Definition: #{hypernym.data.definition}",
      paragraphGap: 8
    doc.fontSize 6
    doc.text "Number of Documents: #{hypernym.docCount} [appears in document: " + hypernym.docs.join(", ") + "]"
    doc.text "Number of Words: #{hypernym.wordCount}"
    doc.text "Words:"
    doc.fontSize 6
    wordString = ""
    for word, count of hypernym.words
      wordString += word + "(" + count + "), "
    doc.text wordString,
      paragraphGap: 8,
      align: "left"
  )
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
