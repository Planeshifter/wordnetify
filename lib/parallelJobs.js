(function() {
  var cluster, exports, numCPUs;

  cluster = require('cluster');

  numCPUs = require('os').cpus().length;

  exports = module.exports = {
    launch: function(msg) {
      var i, _i;
      console.log('Before the fork');
      if (cluster.isMaster) {
        console.log('I am the master, launching workers!');
        for (i = _i = 0; 0 <= numCPUs ? _i < numCPUs : _i > numCPUs; i = 0 <= numCPUs ? ++_i : --_i) {
          cluster.fork();
        }
      } else {
        console.log('I am a worker!');
        console.log(msg);
      }
      return console.log('After the fork');
    }
  };

}).call(this);

//# sourceMappingURL=parallelJobs.js.map
