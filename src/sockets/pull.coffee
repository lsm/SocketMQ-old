{Socket, types} = require './socket'
debug = require('debug')('socketmq:pull')


class PullSocket extends Socket

  constructor: (context, options) ->
    super context, 'pull', options

  handleMessage: (conn, data) ->
    @emit 'message', data
    return @


module.exports = PullSocket
