(function() {
  var PDFDocument, arr, formD3Tree, fs, getNonFlaggedChild, removeFlaggedNodes, renderTitlePage, util, walkTree, writeCorpusPdfReport, writeDocPdfReport, writePDF, _;

  PDFDocument = require('pdfkit');

  fs = require('fs');

  util = require('util');

  _ = require('underscore');

  arr = require('./Array');

  writePDF = function(output, filename, options) {
    if (options == null) {
      options = {};
    }
    if (Array.isArray(output)) {
      return writeDocPdfReport(output, filename, options);
    } else {
      return writeCorpusPdfReport(output, filename, options);
    }
  };

  walkTree = function(current, parent) {
    var child, current_child_lemmas, current_word_lemmas;
    if (current.children.length === 1 && parent !== null) {
      child = current.children[0];
      walkTree(child, current);
      if (current.words !== null) {
        current_word_lemmas = Object.keys(current.words);
        current_child_lemmas = current.children.filter((function(_this) {
          return function(c) {
            return c.words !== null;
          };
        })(this)).map((function(_this) {
          return function(c) {
            return Object.keys(c.words);
          };
        })(this)).reduce((function(_this) {
          return function(a, b) {
            return a.concat(b);
          };
        })(this), []);
        if (current_word_lemmas.compare(current_child_lemmas) === true) {
          current.flagged = true;
        }
      }
      return;
    }
    if (current.children.length === 0) {
      return;
    }
    if (current.children.length > 1 || parent === null) {
      current.children.forEach((function(_this) {
        return function(child) {
          return walkTree(child, current);
        };
      })(this));
    }
  };

  getNonFlaggedChild = function(node) {
    if (node.children[0].flagged === true) {
      return getNonFlaggedChild(node.children[0]);
    } else {
      return node.children[0];
    }
  };

  removeFlaggedNodes = function(current) {
    return current.children.forEach((function(_this) {
      return function(child) {
        var insertNode;
        if (child.flagged === true && child.parentId !== "root") {
          insertNode = getNonFlaggedChild(child);
          current.children = current.children.filter(function(e) {
            return e.data.synsetid !== child.data.synsetid;
          });
          current.children.push(insertNode);
          return removeFlaggedNodes(insertNode);
        } else {
          return removeFlaggedNodes(child);
        }
      };
    })(this));
  };

  formD3Tree = function(tree) {
    var currentNode, key;
    for (key in tree) {
      tree[key].children = [];
    }
    tree["root"] = {};
    tree["root"].children = [];
    for (key in tree) {
      currentNode = tree[key];
      if (currentNode.parentId && tree[currentNode.parentId]) {
        tree[currentNode.parentId].children.push(currentNode);
      }
    }
    walkTree(tree["root"], null);
    removeFlaggedNodes(tree["root"]);
    return tree["root"];
  };

  renderTitlePage = function(doc, filename) {
    var date, subtitle, title, w;
    title = 'Corpus: ' + filename.split(".")[0];
    subtitle = 'Synset Tree Output';
    date = 'generated on ' + new Date().toDateString();
    doc.y = doc.page.height / 2 - doc.currentLineHeight();
    doc.font('Helvetica');
    doc.fontSize(20);
    doc.text(title, {
      align: 'left'
    });
    w = doc.widthOfString(title);
    doc.fontSize(16);
    doc.text(subtitle, {
      align: 'left'
    });
    ({
      indent: w - doc.widthOfString(subtitle)
    });
    doc.text(date, {
      align: 'left'
    });
    ({
      indent: w - doc.widthOfString(date)
    });
    return doc.addPage();
  };

  writeDocPdfReport = function(output, filename, options) {
    return console.log('Should write DOC Reports');
  };

  writeCorpusPdfReport = function(output, filename, options) {
    var doc, printSynset, root, writeStream;
    doc = new PDFDocument();
    writeStream = fs.createWriteStream(filename);
    doc.pipe(writeStream);
    renderTitlePage(doc, filename);
    root = formD3Tree(output.tree);
    printSynset = function(synset, depth) {
      var i, index, obj, printString, spaces, string, wordArr, wordStringArr, _i, _j, _len, _len1;
      doc.fontSize(10);
      doc.fillColor('steelblue');
      doc.text(Array(depth).join("-") + " " + synset.data.words.map((function(_this) {
        return function(e) {
          return e.lemma;
        };
      })(this)).splice(0, 3).join(", ") + (" (w: " + synset.wordCount + ", d: " + synset.docCount + "):"));
      doc.fillColor('black');
      doc.fontSize(6);
      doc.text(Array(depth).join(" ") + synset.data.definition);
      if (options.docReferences) {
        doc.text(Array(depth).join(" ") + "[appears in document: " + synset.docs.join(", ") + "]");
      }
      if (options.includeWords) {
        doc.text(Array(depth).join(" ") + "Words:");
        wordStringArr = [];
        wordArr = _.map(synset.words, (function(_this) {
          return function(count, key) {
            var o;
            o = {};
            o.word = key;
            o.count = count;
            return o;
          };
        })(this)).sort((function(_this) {
          return function(a, b) {
            return b.count - a.count;
          };
        })(this));
        for (i = _i = 0, _len = wordArr.length; _i < _len; i = ++_i) {
          obj = wordArr[i];
          index = Math.floor(i / 12);
          if (index < 5) {
            if (!wordStringArr[index]) {
              wordStringArr[index] = obj.word + "(" + obj.count + "), ";
            } else {
              wordStringArr[index] += obj.word + "(" + obj.count + "), ";
            }
          } else {
            wordStringArr[index] = "...";
            break;
          }
        }
        spaces = Array(depth).join(" ");
        for (_j = 0, _len1 = wordStringArr.length; _j < _len1; _j++) {
          string = wordStringArr[_j];
          printString = spaces + string;
          doc.text(printString);
        }
        doc.text(spaces, {
          paragraphGap: 8
        });
      }
      return synset.children.forEach((function(_this) {
        return function(synset) {
          return printSynset(synset, depth + 1);
        };
      })(this));
    };
    root.children.forEach((function(_this) {
      return function(synset, index) {
        var depth;
        depth = 1;
        return printSynset(synset, depth);
      };
    })(this));
    if (options.includeDocs) {
      doc.addPage;
      doc.fontSize(14);
      doc.fillColor('black');
      doc.text('Corpus Documents', {
        width: 410,
        align: 'center'
      });
      output.corpus.forEach((function(_this) {
        return function(txt, i) {
          doc.font('Times-Roman');
          doc.fontSize(12);
          doc.text("Document " + i + ":");
          doc.fontSize(10);
          return doc.text(txt);
        };
      })(this));
    }
    doc.end();
    return writeStream;
  };

  module.exports = writePDF;

}).call(this);

//# sourceMappingURL=writePDF.js.map
