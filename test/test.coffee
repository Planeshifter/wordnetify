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
thresholdTree                   = require "../lib/thresholdTree"
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
