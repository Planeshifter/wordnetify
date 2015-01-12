(function() {
  var addWorker, client, fibonacci, id, redis;

  redis = require("redis");

  client = redis.createClient();

  id = process.argv[2];

  console.log('START WORKER #{id}');

  client.on('error', function(err) {
    return console.log('Err:' + err);
  });

  fibonacci = function(x) {
    if (x === 0) {
      return 0;
    }
    if (x === 1) {
      return 1;
    }
    return fibonacci(x - 1) + fibonacci(x - 2);
  };

  addWorker = function() {
    return client.blpop('jobs', 0, function(err, data) {
      var result;
      console.log("WORKER " + id + " processing: " + data[1]);
      result = fibonacci(data[1]);
      console.log("WORKER processed " + id + ": " + result);
      client.rpush("results", "" + id + ": " + result);
      return process.nextTick((function() {
        return addWorker();
      }));
    });
  };

  addWorker();

}).call(this);

//# sourceMappingURL=poller.js.map
