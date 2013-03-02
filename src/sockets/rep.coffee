{Socket, types} = require './socket'
debug = require('debug')('socketmq:rep')


class RepSocket extends Socket

  constructor: (context, options) ->
    super context, 'rep', options

  handleMessage: (conn, data) ->

    replied = false
    reply = (data) =>
      if replied
        debug 'you can only reply once for each message'
        return
      replied = true
      @context.send @, conn, data

    @emit 'message', data, reply

module.exports = RepSocket
