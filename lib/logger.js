var winston = require('winston');

winston.add(winston.transports.File, { filename: 'activity.log', silent: false, prettyPrint: true, colorize: true});
winston.remove(winston.transports.Console);

module.exports = winston;
