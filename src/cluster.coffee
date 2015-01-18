cluster = require('cluster')
numCPUs = require('os').cpus().length
workers = []
workerCount = 0

http        = require('http')
url         = require('url')
BPromise    = require('bluebird')
querystring = require('querystring')
exectimer   = require('exectimer')

{ constructSynsetData } = require "./constructSynsetData"
pickSynsets             = require "./pickSynsets"

killWorkers = (signal) ->
  for worker in workers
    worker.kill(signal)

process.on('SIGTERM', () =>
  killWorkers('SIGTERM')
)

if (cluster.isMaster)
  for i in [0...numCPUs]
    worker = cluster.fork()
    workers[i] = worker
  cluster.on('exit', (worker, code, signal) =>
    # console.log('worker ' + worker.process.pid + ' died')
    workerCount--
    if  workerCount == 0 then console.log '\n All workers closed. \n'
  )
  cluster.on('online', (worker) =>
    workerCount++;
    if workerCount == numCPUs then console.log(workerCount + " workers online")
  )

  numServers = 0
  messageHandler = (msg) ->
    if (msg.cmd && msg.cmd == 'listening')
      numServers += 1
      if numCPUs == numServers then  process.send({ msg: 'Workers ready for data processing' })

  Object.keys(cluster.workers).forEach((id) =>
    cluster.workers[id].on('message', messageHandler)
  )
else
  server = http.createServer((request, response) =>
    if (request.method == 'POST')
      queryData = ''
      request.on('data', (data) =>
        queryData += data;
        if(queryData.length > 1e16)
          # prevent data overload
          queryData = ""
          response.writeHead(413, {'Content-Type': 'text/plain'})?.end()
          request.connection.destroy()
          );

      request.on('end', () =>
        pathname = url.parse(request.url).pathname
        response.post = querystring.parse(queryData)
        switch pathname
          when "/getBestSynsets"
            getBestSynsets(response)
      )
  )
  server.setTimeout(0)
  server.listen(8000)
  server.on('listening',() =>
    process.send({ cmd: 'listening' });
  )

getBestSynsets = (response) ->
  doc = JSON.parse(response.post.doc)
  index = response.post.index
  # docTreeMsg = "Construct Candidate Set for Words of Doc " + index
  # console.time(docTreeMsg)
  fWordTree = doc.map( (sentence) => sentence.map ( (w) => constructSynsetData(w, Number index) ) )
  fMsg = BPromise.all(fWordTree).then( (wordTree) =>
    # console.timeEnd(docTreeMsg)
    wordTree = wordTree.map (sentence) => sentence.filter ( (word) => word != null )
    if (wordTree)
      doc = wordTree.map( (sentence) => pickSynsets(sentence) )
      # console.log "Doc #{index} disambiguated. Average time (in ms):" + exectimer.timers.pickSynsets.mean() 
    else
      doc = null
    return JSON.stringify(doc)
  ).then( (msg) =>
    response.end(msg)
  )
