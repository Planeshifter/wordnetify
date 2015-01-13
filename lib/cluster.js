(function() {
  var BPromise, cluster, constructSynsetData, createDocTree, getBestSynsets, getDocTree, http, i, messageHandler, numCPUs, numServers, pickSynsets, querystring, server, url, worker, workerCount, workers, _i;

  cluster = require('cluster');

  numCPUs = require('os').cpus().length;

  workers = [];

  workerCount = 0;

  http = require('http');

  url = require('url');

  BPromise = require('bluebird');

  querystring = require('querystring');

  constructSynsetData = require("./constructSynsetData").constructSynsetData;

  createDocTree = require("./synsetRepresentation").createDocTree;

  pickSynsets = require("./pickSynsets");

  if (cluster.isMaster) {
    for (i = _i = 0; 0 <= numCPUs ? _i < numCPUs : _i > numCPUs; i = 0 <= numCPUs ? ++_i : --_i) {
      worker = cluster.fork();
      workers[i] = worker;
    }
    cluster.on('exit', (function(_this) {
      return function(worker, code, signal) {
        return console.log('worker ' + worker.process.pid + ' died');
      };
    })(this));
    cluster.on('online', (function(_this) {
      return function(worker) {
        workerCount++;
        if (workerCount === numCPUs) {
          return console.log(workerCount + " workers online");
        }
      };
    })(this));
    numServers = 0;
    messageHandler = function(msg) {
      if (msg.cmd && msg.cmd === 'listening') {
        numServers += 1;
        if (numCPUs === numServers) {
          return process.send({
            msg: 'Workers ready for data processing'
          });
        }
      }
    };
    Object.keys(cluster.workers).forEach((function(_this) {
      return function(id) {
        return cluster.workers[id].on('message', messageHandler);
      };
    })(this));
  } else {
    server = http.createServer((function(_this) {
      return function(request, response) {
        var queryData;
        if (request.method === 'POST') {
          queryData = '';
          request.on('data', function(data) {
            var _ref;
            queryData += data;
            if (queryData.length > 1e9) {
              queryData = "";
              if ((_ref = response.writeHead(413, {
                'Content-Type': 'text/plain'
              })) != null) {
                _ref.end();
              }
              return request.connection.destroy();
            }
          });
          return request.on('end', function() {
            var pathname;
            pathname = url.parse(request.url).pathname;
            response.post = querystring.parse(queryData);
            switch (pathname) {
              case "/getBestSynsets":
                return getBestSynsets(response);
              case "/getDocTree":
                return getDocTree(response);
            }
          });
        }
      };
    })(this));
    server.setTimeout(0);
    server.listen(8000);
    server.on('listening', (function(_this) {
      return function() {
        return process.send({
          cmd: 'listening'
        });
      };
    })(this));
  }

  getDocTree = function(response) {
    var doc, fMsg, index, res;
    doc = JSON.parse(response.post.doc);
    index = response.post.index;
    res = createDocTree(doc);
    fMsg = getBestSynsets(res, index);
    return fMsg.then((function(_this) {
      return function(msg) {
        return response.end(msg);
      };
    })(this));
  };

  getBestSynsets = function(doc, index) {
    var fWordTree;
    fWordTree = doc.map((function(_this) {
      return function(w) {
        return constructSynsetData(w, index);
      };
    })(this));
    return BPromise.all(fWordTree).then((function(_this) {
      return function(wordTree) {
        wordTree = wordTree.filter(function(word) {
          return word !== null;
        });
        if (wordTree) {
          doc = pickSynsets(wordTree);
        } else {
          doc = null;
        }
        return JSON.stringify(doc);
      };
    })(this));
  };

}).call(this);

//# sourceMappingURL=cluster.js.map
