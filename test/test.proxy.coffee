{expect} = require 'chai'
SocketMQ = require '../'
http = require 'http'
io = require 'socket.io'
ioClient = require 'socket.io-client'

describe 'SocketMQ.proxy', () ->
  server = context = null


  beforeEach () ->
    server = http.createServer () ->
    context = SocketMQ.listen(server)

  describe 'ROUTER <=> DEALER proxy', () ->
    it 'should throw if the argument is not instanceof SocketMQ.Socket', () ->
      fn = () ->
        SocketMQ.proxy({}, {}, {})
      expect(fn).to.throw(/can only proxy between instance of SocketMQ\.Socket/)

    it 'should forward message from frontend (SocketMQ) to backend (SocketMQ)', (done) ->
      server = context.listen 8888, '127.0.0.1', () ->
        # create and bind frontend socket
        frontend = context.socket SocketMQ.ROUTER
        frontend.bind 'smq://frontend', (err) ->
          if err then throw err

        # create and bind backend socket
        backend = context.socket SocketMQ.DEALER
        backend.bind 'smq://backend', (err) ->
          if err then throw err

        # proxy frontend message to backend 
        SocketMQ.proxy(frontend, backend)

        # A SocketMQ client context
        clientContext = SocketMQ.connect 'http://127.0.0.1:8888'

        # create the request socket and connect to frontend
        reqSocket = clientContext.socket SocketMQ.REQ
        reqSocket.connect 'smq://frontend'

        # create the reply socket and connect to backend
        repSocket = clientContext.socket SocketMQ.REP
        repSocket.connect 'smq://backend'

        # listen event of reply socket
        repSocket.on 'message', (data) ->
          expect(data).to.be.instanceof(Buffer)
          expect(data.toString()).to.eql('hello')
          repSocket.send 'world'

        # listen event of request socket
        reqSocket.on 'message', (data) ->
          expect(data).to.be.instanceof(Buffer)
          expect(data.toString()).to.eql('world')
          server.close()
          done()

        # send the initial request message
        reqSocket.send 'hello'    

    it 'should forward message from frontend (SocketMQ) to backend (ZeroMQ)', (done) ->

    it 'should forward message from frontend (ZeroMQ) to backend (SocketMQ)', (done) ->

    it 'should capture messages passing by with PUB socket', (done) ->
    it 'should capture messages passing by with DEALER socket', (done) ->
    it 'should capture messages passing by with PUSH socket', (done) ->

  describe 'XSUB <=> XPUB', () ->

    it 'should forward message from frontend (SocketMQ) to backend (SocketMQ)', (done) ->

    it 'should forward message from frontend (SocketMQ) to backend (ZeroMQ)', (done) ->

    it 'should forward message from frontend (ZeroMQ) to backend (SocketMQ)', (done) -> 

    it 'should capture messages passing by with PUB socket', (done) ->
    it 'should capture messages passing by with DEALER socket', (done) ->
    it 'should capture messages passing by with PUSH socket', (done) ->

  describe 'PULL <=> PUSH', () ->

    it 'should forward message from frontend (SocketMQ) to backend (SocketMQ)', (done) ->

    it 'should forward message from frontend (SocketMQ) to backend (ZeroMQ)', (done) ->

    it 'should forward message from frontend (ZeroMQ) to backend (SocketMQ)', (done) -> 

    it 'should capture messages passing by with PUB socket', (done) ->
    it 'should capture messages passing by with DEALER socket', (done) ->
    it 'should capture messages passing by with PUSH socket', (done) ->
    