###
Context class use to create different type of sockets and abstract the transport layer.
###

http = require 'http'
engine = require 'engine.io'
engineClient = require 'engine.io-client'
debug = require('debug')('socketmq:context')
{EventEmitter} = require 'events'
{types, Socket, sockets} = require './sockets'
qsParse = require('querystring').parse
urlParse = require('url').parse


class Context extends EventEmitter

  constructor: (@options) ->
    @sockets = {}
    @connections = {}

  socket: (type, options) ->
    Sock = sockets[type]
    if 'function' isnt typeof Sock
      throw new Error 'Unknow socket type "' + type + '"'
    return new Sock(@, options)

  # client methods
  connect: (url, options = {}) ->
    if 'string' is typeof url
      options.path = options.path || '/socketmq'
      @client = engineClient url, options
    else
      @client = url

    # Engine.io "open" packet sent from "server"
    @client.on 'handshake', (data) =>
      debug '[HS0] client handling handshake data %j', data

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
      @handleConnection @client, { id: @client.id, endpoint: socket.endpoint, type: socket.type }
    else
      @client.on 'open', (data) =>
        data =
          id: @client.id
          endpoint: socket.endpoint
          type: socket.type
          smq: 0x01
        data = JSON.stringify data

        onPacket = (packet) =>
          if 'noop' is packet.type
            data = JSON.parse packet.data
            if data.smq
              debug '[HS4] client finished handshake and got noop packet data from server: %s', packet.data
              @client.smq = data.smq
              @client.removeListener 'packet', onPacket
              @handleConnection @client, data

        @client.on 'packet', onPacket

        debug '[HS1] client sending noop packet to server with data %s', data
        @client.sendPacket 'noop', data

  # server methods
  listen: (port, host, options, fn) ->
    opts =
      path: '/socketmq'
    if not fn
      if 'function' is typeof options
        fn = options
        options = null
      else if  'function' is typeof host
        fn = host
        host = null
    if typeof port is 'number'
      httpServer = http.createServer options
      httpServer.listen port, host
      @server = engine.attach httpServer, opts
      @server.httpServer = httpServer
    else if port instanceof http.Server
      @server = engine.attach port, opts
      @server.httpServer = port
    else
      fn {code: 'EINVALIDARGS', message: "First argument of Context#listen must be instance of http.Server or port number"}
      return @

    @server.httpServer.on 'listening', (args...) =>
      fn && fn args...
      for endpoint, socket of @sockets
        for callback in socket.bindCallbacks
          callback args...

    @server.on 'connection', (conn) =>
      debug 'server handling new connection ', conn.id
      onPacket = (packet) =>
        if 'noop' is packet.type
          data = JSON.parse packet.data
          if data.smq
            debug '[HS2] server got handshake data from client: %s', packet.data
            conn.smq = data.smq
            conn.removeListener 'packet', onPacket
            @handleConnection conn, data

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

          for k, v of meta
            data[k] = v
          # the socket type of conn is client socket type
          # we need to set the type to server socket type when sending back to client
          # other properties should be same
          data.type = socket.type
          data = JSON.stringify data
          debug '[HS3] server finished handshake and send noop packet to client %s', data
          conn.sendPacket 'noop', data

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
    if @connections[conn.endpoint] and @connections[conn.endpoint][conn.id]
      connection = @connections[conn.endpoint][conn.id]
      connection.send data
    else
      debug 'Writing data to an inexistent connection %s at endpoint %s', conn.id, conn.endpoint

  close: ->
    for k, sock of @sockets
      sock.close()

    if @server
      @server.close()

    if @client
      @client.close()


module.exports = Context
