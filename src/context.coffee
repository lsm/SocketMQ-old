###
Context class use to create different type of sockets and abstract the transport layer.
###

http = require 'http'
engine = require 'engine.io'
engineClient = require 'engine.io-client'
debug = require('debug')('socketmq:context')
{EventEmitter} = require 'events'
{types, Socket} = require './sockets'
qsParse = require('querystring').parse
urlParse = require('url').parse


class Context extends EventEmitter
  
  constructor: (@options) ->
    @sockets = {}
    @connections = {}

  socket: (type, options) ->
    new Socket(@, type, options)

  # client methods
  connect: (url, options) ->
    if 'string' is typeof url
      @client = engineClient url, options
    else
      @client = url

    # Engine.io "open" packet sent from "server"
    @client.on 'handshake', (data) =>
      debug 'Handshake data %s', data
      if data.smq
        @client.smq = data.smq
        @handleConnection @client, data
      else
        # original engine.io handshake, emit the data
        # add socketmq options and send an "open" packet to server upon handshake
        @emit 'handshake', data
    
    return @
    
  handshake: (socket) ->
    ###
      when received handshake data from server
      add socket info to received data and send an "open" packet to server
      the server will reply an "open" packet with server endpoint info
      or close the connection if the socket type miss match (e.g. connect req to req)
    ###
    if @client.smq
      # the underlying connection already handshaked
      # try to handle the connection with given socket properties
      @handleConnection @client, { id: client.id, endpoint: socket.endpoint, type: socket.type }
    else
      @once 'handshake', (data) ->
        data.id = data.sid
        data.endpoint = socket.endpoint
        data.type = socket.type
        data.smq = 0x01
        @client.sendPacket 'open', data

  # server methods
  listen: (port, host, options, fn) ->
    opts = 
      path: '/socketmq'
    if not fn 
      if typeof options is 'function'
        fn = options
      else if typeof host is 'function'
        fn = host
    if typeof port is 'number'
      httpServer = http.createServer options
      httpServer.listen port, host
      @server = engine.attach httpServer, opts
    else if port instanceof http.Server
      @server = engine.attach port, opts
    else
      fn {code: 'EINVALIDARGS', message: "First argument of Context#listen must be instance of http.Server or port number"}
      return @

    fn && @server.httpServer.on 'listening', (args...) =>
      fn args...
      for endpoint, socket of @sockets
        for callback in socket.bindCallbacks
          callback args...
    
    @server.on 'connection', (conn) =>
      onPacket = (packet) =>
        if 'open' is packet.type
          debug 'Handshake data from client: %s', packet.data
          data = packet.data
          conn.smq = data.smq
          @handleConnection conn, data
          conn.off 'packet', onPacket

      conn.on 'packet', onPacket
    return @

  setSocket: (endpoint, socket) ->
    if endpoint in @sockets
      throw new Error 'Endpoint ' + endpoint + ' already in use'
    @sockets[endpoint] = socket
    return @
  
  getSocket: (endpoint) ->
    return endpoint && @sockets[endpoint]

  # handle engine.io connection and find a proper socket to handle it
  handleConnection: (conn, meta) ->
    if conn.smq
      # socketmq handshaked connection
      {id, endpoint, type} = meta
      socket = @getSocket endpoint

      if not socket
        debug 'Unknow destination endpoint'
        conn.close()
      else if socket.accept type
        if conn.server
          # connection on server side, need to reply an open packet to client
          data = {}
          for k, v in meta
            data[k] = v
          # the socket type of conn is client socket type
          # we need to set the type to server socket type when sending back to client
          # other properties should be same
          data.type = socket.type
          conn.sendPacket 'open', data

        connections = @connections
        if not connections[endpoint] then connections[endpoint] = {}
        connMeta = { id: id, endpoint: endpoint, type: type }

        if not connections[endpoint][id]
          connections[endpoint][id] = conn
          # one connection may be used by multilple socketmq socket
          # close event should be handled once for the same connection
          conn.once 'close', (reason, info) ->
            if connections[endpoint][id]
              debug 'Engine.io client socket closed: %s', reason
              delete connections[endpoint][id]
              socket.handleDisconnect connMeta
              @emit 'disconnect', connMeta
            else
              debug 'Closing an inexistent engine.io socket'

        conn.on 'message', (data) ->
          socket.handleMessage connMeta, data

        socket.handleConnect connMeta
      else
        debug 'Not accepted socket type: %s', type
        conn.close()
    else
      debug 'Not a SocketMQ connection, closing...'
      conn.close()
      
  send: (socket, conn, data) ->
    connection = @connections[conn.endpoint][conn.id]
    connection.send data

  close: ->
    
  
  



module.exports = Context



