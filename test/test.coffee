_ = require 'underscore'
chai = require "chai"
chaiAsPromised = require "chai-as-promised"
chai.use(chaiAsPromised)

BPromise = require "bluebird"
util = require "util"
expect = chai.expect
assert = chai.assert
should = chai.should()

{ getCorpusSynsets }            = require "../lib/synsetRepresentation"
{ constructSynsetData, SynsetNode }         = require "../lib/constructSynsetData"
pickSynsets                     = require "../lib/pickSynsets"
{ generateCorpusTree, generateWordTree } = require "../lib/treeGenerator"
calculateCounts                 = require "../lib/counting"
{ thresholdDocTree, thresholdWordTree } = require "../lib/thresholdTree"

describe "Analyze a single document", () ->
  doc = "I am a single document and have no regrets about it"
  candidates = getCorpusSynsets(doc)
  docTrees = candidates.map( (d, index) =>
    wordTrees = d.map( (w) => constructSynsetData(w, index) )
    return wordTrees.filter( (word) => word != null )
  )
  fPrunedDocTrees = docTrees.filter( (doc) => doc != null).map( (doc) =>
    pickSynsets(doc)
  )
  fCorpusTree = BPromise.all(fPrunedDocTrees).then( (docTrees) =>
    return generateCorpusTree(docTrees)
  )
  fFinalTree = fCorpusTree.then( (corpusTree) => calculateCounts(corpusTree) )

  thresholdLevel = 2
  fThresholdedTree = fFinalTree.then( (finalTree) =>
    returnTree = _.clone(finalTree)
    thresholdDocTree(returnTree, thresholdLevel)
  )

  describe "getCorpusSynsets():", () =>
    it "should return an array (for each doc) of arrays (storing the words and their candidate synsets)", () =>
      synset = candidates[0][0]
      expect(synset).to.be.a("object")
      expect(synset).to.include.keys(["baseWords","count","string","synsets"])
  describe "construcSynsetData():", () =>
    it "should map each word object to an array of synset candidates (of class SynsetNode)", () =>
      synsetArrays = docTrees.map( (w) => w[0][0])
      expect(synsetArrays[0]).to.be.instanceof(SynsetNode)
      expect(synsetArrays[0]).to.have.keys(["synsetid","isCandidate","data","wordCount","docs","docCount","words","baseWords","parentId","score"])
  describe "pickSynsets()", () =>
    it "should pick a single synset depending on similarity scores", () =>
      assertions = []
      fPrunedDocTrees.forEach( (w) => w.forEach( (k) => assertions.push(expect(k).to.have.property("synsetid") )))
  describe "generateCorpusTree()", () =>
    it "should create a hash table holding all tree synsets", () =>
      assertions = []
      fCorpusTree.then( (corpusTree) =>
        fPrunedDocTrees.forEach( (w) =>
          w.forEach( (k) =>
            assertions.push( expect(corpusTree).to.have.property(k.synsetid) )
          )
        )
      )
  describe "calculateCounts()", () =>
    it "should correctly calculate all word counts", () =>
      fFinalTree.then( (finalTree) =>
        for id, synset of finalTree
          wordCount = _.reduce(synset.words, (memo, count) =>
            memo + count
          , 0)
          expect(wordCount).to.be.equal(synset.wordCount)
      )
    it "should correctly calculate all document counts", () =>
      fFinalTree.then( (finalTree) =>
        for id, synset of finalTree
          docCount = synset.docs.length
          expect(docCount).to.be.equal(synset.docCount)
      )

  describe "thresholdDocTree()", () =>
    it "should remove all synsets in the hash table with docCount < threshold", () =>
      fThresholdedTree.then( (tree) =>
        assertions = []
        for id, synset of tree
          assertions.push( expect(synset.docCount).to.be.at.least(thresholdLevel) )
      )
