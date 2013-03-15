socket = require('./socket')

for k, v of socket
  exports[k] = v

sockets =
  req: require './req'
  rep: require './rep'
  pub: require './pub'
  sub: require './sub'
  push: require './push'
  pull: require './pull'


exports.sockets = sockets
