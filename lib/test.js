'use strict';
var _ = require('lodash');
var Parallel = require('paralleljs');
console.log(_.name);
console.time('time');

// Create a job
var p = new Parallel(100000, {
    env: {
        a: 10
    },
    envNamespace: 'parallel'
});

// Spawn a remote job (we'll see more on how to use then later)
var slowSquare = function (n) {
    console.log(global.GLOBAL);
    //_.isString('true');
    var i = 0;
    while (++i < n * n) {}
    return i;
};

function yourCallback(data) {
    console.log(data);
    console.timeEnd('time');
}

// Spawn our slow function
p.spawn(slowSquare).then(yourCallback);
