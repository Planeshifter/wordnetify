var winston = require('winston');

/*
winston.add(winston.transports.File, { filename: 'activity.log', silent: false});
winston.add(winston.transports.Console, {prettyPrint: true});
*/

var logger = new (winston.Logger)({
    transports: [
      new (winston.transports.Console)({ prettyPrint: true, colorize: true, timestamp: false, json: true}),
      new (winston.transports.File)({ filename: 'activity.log', prettyPrint: true })
    ]
  });

module.exports = logger;
