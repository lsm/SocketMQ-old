{Socket, types} = require './socket'
debug = require('debug')('socketmq:rep')


class RepSocket extends Socket

  constructor: (context, options) ->
    super context, 'rep', options
    @inBuffer = []
    # If we have last connection we are in process of sending the reply
    # If we don't have lastConn then we are in process of receiving request
    @lastConn = null

  send: (data) ->
    if @lastConn
      @context.send @, @lastConn, data
      @lastConn = null
    else
      # didn't get request since last reply, drop the data
      @drop data, "Cannot send reply until next request recevied"

    if @inBuffer.length > 0
      msg = @inBuffer.shift()
      @handleMessage msg.conn, msg.data

  handleMessage: (conn, data) ->
    if @lastConn is null
      @lastConn = conn
      @emit 'message', data
    else
      @inBuffer.push {conn: conn, data: data}


module.exports = RepSocket
