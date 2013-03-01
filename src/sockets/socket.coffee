
{EventEmitter} = require 'events'
debug = require('debug')('socketmq:socket')

###
Types of socket
###
types = exports.types =
  pair: 0x00
  pub: 0x01
  sub: 0x02
  req: 0x03
  rep: 0x04
  dealer: 0x05
  router: 0x06
  pull: 0x07
  push: 0x08

###
Base class for different socket patterns
###
class Socket extends EventEmitter

  constructor: (context, type, options) ->
    if types[type] is undefined
      throw new Error 'Unknow socket type "' + type + '"'

    @context = context
    @type = types[type]
    @outBuffer = []
    @connections = []
    @bindCallbacks = []

  connect: (url) ->
    @context.setSocket url, @
    @endpoint = url
    @context.handshake @

  bind: (endpoint, callback) ->
    @context.setSocket endpoint, @
    if 'function' is typeof callback
      @bindCallbacks.push callback

  setsockopt: (name, value) ->

  getsockopt: (name) ->

  accept: (type) ->
    type = types[type] ? type
    switch @type
      when types.pair
        return type is types.pair
      when types.pub
        return type is types.sub
      when types.sub
        return type is types.pub
      when types.req
        return type is types.rep or type is types.router
      when types.rep
        return type is types.req or type is types.dealer
      when types.dealer
        return type is types.rep or type is types.dealer or type is types.router
      when types.router
        return type is types.req or type is types.dealer or type is types.router
      when types.pull
        return type is types.push
      when types.push
        return type is types.pull

  drop: (msg, reason) ->
    debug 'Message "' + msg + '" dropped due to ' + reason
    @emit 'drop', msg, reason

  handleConnect: (conn) ->
    @emit 'connect', conn
    if conn not in @connections
      @connections.push conn

  handleDisconnect: (conn) ->
    idx = @connections.indexOf conn
    if idx > -1
      @emit 'disconnect', conn
      @connections.splice idx, 1

  close: ->
    if not @closed
      @closed = true
      @emit 'close'
      @connections = []
      @outBuffer = []

  flushRoundRobin: (data) ->
    if @connections.length > 0 and !@flushing
      @flushing = true
      @outBuffer.push data

      while @connections.length > 0 and @outBuffer.length > 0
        @context.send @, @connections.shift(), @outBuffer.shift()

      @flushing = false
    else if @outBuffer.length >= @hwm
      @drop data, 'high water mark reached (#{@hwm})'
    else
      @outBuffer.push data

exports.Socket = Socket
