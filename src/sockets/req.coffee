{Socket, types} = require './socket'


class ReqSocket extends Socket

  constructor: (context, options) ->
    super context, types.req, options
    @flushing = false

  send: (data) ->
    @flushRoundRobin data  

  handleMessage: (conn, data) ->
    if not @accept conn.type
      drop data, 'socket type #{conn.type} not accepted'

    @connections.push conn
    @emit 'message', data
    @flushRoundRobin()
    
  handleConnect: (conn) ->
    super conn
    @flushRoundRobin()


module.exports = ReqSocket
  


  
  
  