(function() {
  var PDFDocument, doc, file, fs, key, leafs, output, value, _ref;

  PDFDocument = require('pdfkit');

  fs = require('fs');

  doc = new PDFDocument;

  doc.pipe(fs.createWriteStream('output.pdf'));

  file = fs.readFileSync("fruits.json");

  output = JSON.parse(file);

  leafs = [];

  _ref = output.tree;
  for (key in _ref) {
    value = _ref[key];
    if (value.isCandidate === true) {
      leafs.push(value);
    }
  }

  console.log(leafs);

  doc.fontSize(16);

  doc.text('Synsets', {
    width: 410,
    align: 'center'
  });

  leafs.forEach((function(_this) {
    return function(synset, i) {
      var ancestors, count, current, word, wordString, _ref1;
      doc.fontSize(12);
      doc.fillColor('steelblue');
      doc.text("Leaf: " + synset.data.words.map(function(e) {
        return e.lemma;
      }).join(", "));
      doc.fillColor('black');
      doc.fontSize(8);
      doc.text("Definition: " + synset.data.definition);
      doc.text(("Number of Documents: " + synset.docCount + " [appears in document: ") + synset.docs.join(", ") + "]");
      doc.text("Number of Words: " + synset.wordCount);
      doc.fontSize(6);
      doc.text("Words:");
      wordString = "";
      console.log(synset);
      _ref1 = synset.words;
      for (word in _ref1) {
        count = _ref1[word];
        console.log(word);
        wordString += word + "(" + count + "), ";
      }
      doc.text(wordString, {
        paragraphGap: 8
      });
      doc.fontSize(10);
      doc.text('Hypernyms:');
      ancestors = [];
      current = synset;
      while (current && current.parentId !== "root") {
        ancestors.push(current.parentId);
        console.log(current.parentId);
        current = output.tree[current.parentId];
      }
      console.log(ancestors);
      return ancestors.forEach(function(id, i) {
        var hypernym, _ref2;
        hypernym = output.tree[id];
        doc.fontSize(8);
        doc.fillColor('steelblue');
        doc.text(Array(i + 1).join("  ") + hypernym.data.words.map(function(e) {
          return e.lemma;
        }).join(", "));
        doc.fillColor('black');
        doc.text(Array(i + 1).join("  ") + ("Definition: " + hypernym.data.definition), {
          paragraphGap: 8
        });
        doc.fontSize(6);
        doc.text(("Number of Documents: " + hypernym.docCount + " [appears in document: ") + hypernym.docs.join(", ") + "]");
        doc.text("Number of Words: " + hypernym.wordCount);
        doc.text("Words:");
        doc.fontSize(6);
        wordString = "";
        _ref2 = hypernym.words;
        for (word in _ref2) {
          count = _ref2[word];
          wordString += word + "(" + count + "), ";
        }
        return doc.text(wordString, {
          paragraphGap: 8,
          align: "left"
        });
      });
    };
  })(this));

  doc.addPage;

  doc.fontSize(16);

  doc.fillColor('black');

  doc.text('Corpus Documents', {
    width: 410,
    align: 'center'
  });

  output.corpus.forEach((function(_this) {
    return function(txt, i) {
      doc.font('Times-Roman');
      doc.fontSize(14);
      doc.text("Document " + i + ":");
      doc.fontSize(10);
      return doc.text(txt);
    };
  })(this));

  doc.end();

}).call(this);

//# sourceMappingURL=writePDF.js.map
