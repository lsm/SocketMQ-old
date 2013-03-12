{Socket, types} = require './socket'


class ReqSocket extends Socket

  constructor: (context, options) ->
    super context, 'req', options
    @flushing = false

  send: (data) ->
    # toSend = new Buffer(Buffer.byteLength(data) + 1)
    # toSend[0] = '\0' # the null delimiter
    # toSend.concat(new Buffer(data))
    @flushRoundRobin data

  handleMessage: (conn, data) ->
    # data = data.slice 1
    @connections.push conn
    @emit 'message', data
    @flushRoundRobin()

  handleConnect: (conn) ->
    super conn
    @flushRoundRobin()

module.exports = ReqSocket
