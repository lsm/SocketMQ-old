{Socket, types} = require './socket'
debug = require('debug')('socketmq:push')


class PushSocket extends Socket

  constructor: (context, options) ->
    super context, 'push', options
    @flushing = false
    @n = 0

  send: (data) ->
    @flushRoundRobin data

  handleConnect: (conn) ->
    super conn
    @flushRoundRobin()

  flushRoundRobin: (data) ->
    len = @connections.length
    if len > 0 and !@flushing
      console.log 'plush'
      @flushing = true
      if 'undefined' isnt typeof data then @outBuffer.push data

      while @outBuffer.length > 0
        conn = @connections[@n++ % len]
        @context.send @, conn, @outBuffer.shift()

      @flushing = false
    else if 'undefined' isnt typeof data
      if @outBuffer.length >= @hwm
        @drop data, 'high water mark reached (#{@hwm})'
      else
        @outBuffer.push data


module.exports = PushSocket
