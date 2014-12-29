cluster = require('cluster')
numCPUs = require('os').cpus().length
workers = []

http        = require('http')
url         = require('url')
BPromise    = require('bluebird')
querystring = require('querystring')

{ constructSynsetData } = require "./constructSynsetData"
pickSynsets             = require "./pickSynsets"

if (cluster.isMaster)
  for i in [0...numCPUs]
    worker = cluster.fork()
    workers[i] = worker

  cluster.on('exit', (worker, code, signal) =>
    console.log('worker ' + worker.process.pid + ' died')
  )
else
  http.createServer((request, response) =>
    if (request.method == 'POST')
      queryData = ''
      request.on('data', (data) =>
        queryData += data;
        if(queryData.length > 1e6)
          # prevent data overload
          queryData = ""
          response.writeHead(413, {'Content-Type': 'text/plain'}).end()
          request.connection.destroy()
          );

      request.on('end', () =>
        pathname = url.parse(request.url).pathname
        response.post = querystring.parse(queryData)
        console.log(response.post)
        # x = JSON.parse(response.post.data)
        switch pathname
          when "/getBestSynsets"
            console.log("Daten sind angekommen")
            getBestSynsets(response)
      )

  ).listen(8000)


getBestSynsets = (response) ->
  doc = JSON.parse(response.post.doc)
  index = response.post.index
  docTreeMsg = "Construct Candidate Set for Words of Doc " + index
  console.time(docTreeMsg)
  fWordTree = doc.map( (w) => constructSynsetData(w, index) )
  BPromise.all(fWordTree).then( (wordTree) =>
    console.timeEnd(docTreeMsg)
    wordTree = wordTree.filter( (word) => word != null )
    if (wordTree)
      doc = pickSynsets(wordTree)
    else
      doc = null
    msg = JSON.stringify(doc)
    response.end(msg)
  )
