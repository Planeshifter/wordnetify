winston = require 'winston'

logger = new (winston.Logger)({
  transports: [
    new (winston.transports.Console)({
      prettyPrint: true,
      colorize: true,
      timestamp: false,
      json: true,
      silent: true}),
    new (winston.transports.File)({
      filename: 'activity.log',
      prettyPrint: true })
  ]
})

module.exports = exports = logger
