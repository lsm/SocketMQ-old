http = require 'http'
Context = require './context'
socket = require './sockets'
eio = require 'engine.io'

exports.version = '0.0.0'
exports.Context = Context
for k, v of socket
  exports[k] = v


exports.listen = (port, host, options, callback) ->
  if 'number' isnt typeof port and port not instanceof http.Server
    throw new Error "First argument of SocketMQ#listen must be instance of http.Server or port number"
  context = new Context
  return context.listen port, host, options, callback


exports.connect = (url) ->
  context = new Context
  return context.connect url

exports.proxy = () ->



