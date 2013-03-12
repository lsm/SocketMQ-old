{Socket, types} = require './socket'
debug = require('debug')('socketmq:pub')


class PubSocket extends Socket

  constructor: (context, options) ->
    super context, 'pub', options

  send: (data) ->
    for conn in @connections
      @context.send @, conn, data

module.exports = PubSocket
