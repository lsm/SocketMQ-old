{expect} = require 'chai'
SocketMQ = require '../'
http = require 'http'

# context = SocketMQ.listen 8888, '127.0.0.1'
# console.log 'context is instanceof Context %s', context instanceof SocketMQ.Context

server = http.createServer()
context = SocketMQ.listen(server)      
socket = context.socket 'req'

describe 'SocketMQ.Context', () ->
  server = null
    
  describe '#constructor', () ->
    it 'should throw if the first argument is not instance of http.Server or port number', () ->
      fn = () ->
        SocketMQ.listen({})
      expect(fn).to.throw(/must be instance of http\.Server or port number/)

    it 'should create context by listening to port and host', () ->
      context = SocketMQ.listen 8888, '127.0.0.1'
      expect(context).to.be.instanceof(SocketMQ.Context)

    it 'should create context by listening to the http.Server instance', () ->
      server = http.createServer()
      context = SocketMQ.listen(server)
      expect(context).to.be.instanceof(SocketMQ.Context)

    it 'should create context by calling connect method', () ->
      connectContext = SocketMQ.connect 'http://127.0.0.1:8888'
      expect(connectContext).to.be.instanceof(SocketMQ.Context)
      

  describe '#socket', () ->
    it 'should return instance of Socket', () ->
      server = http.createServer()
      context = SocketMQ.listen(server)      
      socket = context.socket 'req'
      expect(socket).to.be.instanceof(SocketMQ.Socket)

    it 'should throw unknow socket type exception if the given socket type is invalid', () ->
      server = http.createServer()
      context = SocketMQ.listen(server)
      fn = () ->
        context.socket('happy')
      expect(fn).to.throw(/unknow socket type "happy"/i)



        
          
      
      