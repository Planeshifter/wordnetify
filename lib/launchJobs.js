(function() {
  var addWorker, array, async, client, cp, cpu, numCPUs, redis, results, workers, _i;

  cp = require('child_process');

  redis = require("redis");

  async = require("async");

  client = redis.createClient();

  numCPUs = require('os').cpus().length;

  console.log("CPU number: " + numCPUs);

  workers = [];

  array = [10, 11, 36, 10, 12, 26, 10, 40, 36, 33, 34, 11];

  async.each(array, (function(item, callback) {
    client.rpush("jobs", item);
    return callback(null);
  }));

  for (cpu = _i = 0; 0 <= numCPUs ? _i <= numCPUs : _i >= numCPUs; cpu = 0 <= numCPUs ? ++_i : --_i) {
    workers.push(cp.fork('./src/poller.coffee', [cpu]));
  }

  results = [];

  addWorker = function() {
    return client.blpop('results', 0, function(err, data) {
      var worker, _j, _len, _results;
      results.push(data[1]);
      if (results.length === array.length) {
        console.log(results);
        client.quit();
        _results = [];
        for (_j = 0, _len = workers.length; _j < _len; _j++) {
          worker = workers[_j];
          _results.push(worker.kill('SIGHUP'));
        }
        return _results;
      } else {
        return process.nextTick((function() {
          return addWorker();
        }));
      }
    });
  };

  addWorker();

  console.log("started...");

}).call(this);

//# sourceMappingURL=launchJobs.js.map
