(function() {
  var postData, rp;

  rp = require('request-promise');

  postData = {
    a: 1,
    index: 2
  };

  rp.post('http://localhost:8000/getBestSynsets', {
    body: require('querystring').stringify(postData)
  }).then((function(_this) {
    return function(response) {
      return console.log(response);
    };
  })(this))["catch"](console.error);

}).call(this);

//# sourceMappingURL=servercom.js.map
