{expect} = require 'chai'
SocketMQ = require '../'
http = require 'http'


describe 'SocketMQ.socket REQ/REP', () ->
  server = serverContext = clientContext = null
  msgText = 'hello'

  beforeEach () ->
    server = http.createServer () ->
    serverContext = SocketMQ.listen(server)
    server.listen 8888, '127.0.0.1'
    clientContext = SocketMQ.connect('http://127.0.0.1:8888')

  it 'should send request and get reply', (done) ->
    server.on 'listening', () ->
      # create the reply server socket
      repSocket = serverContext.socket SocketMQ.REP
      
      # handle message
      repSocket.on 'message', (data) ->
        expect(data).to.be.instanceof(Buffer)
        expect(data.toString()).to.be.eql(msgText)
        repSocket.send data
      
      # bind reply socket to specified endpoint
      repSocket.bind 'smq://echo', (err) ->
        if err then throw err
        
        # create the request socket and connect
        reqSocket = SocketMQ.connect('http://127.0.0.1:8888').socket(SocketMQ.REQ)
        reqSocket.connect 'smq://echo'
        
        # handle message
        reqSocket.on 'message', (data) ->
          expect(data).to.be.instanceof(Buffer)
          expect(data.toString()).to.be.eql(msgText)
          reqSocket.close()
          repSocket.close()
          server.close()
          done()

        # send out the initial request message
        reqSocket.send msgText
        
  it 'should bind request socket and get echo message from reply socket', (done) ->
    server.on 'listening', () ->
      # create the reply client socket
      repSocket = clientContext.socket SocketMQ.REP
      # connect the reply socket
      repSocket.connect 'smq://echo'
      
      # handle message
      repSocket.on 'message', (data) ->
        expect(data).to.be.instanceof(Buffer)
        expect(data.toString()).to.be.eql(msgText)
        repSocket.send data

      # create the request spcket
      reqSocket = serverContext.socket SocketMQ.REQ
      
      # bind request socket to specified endpoint
      reqSocket.bind 'smq://echo', (err) ->
        if err then throw err
        
        # handle message
        repSocket.on 'message', (data) ->
          expect(data).to.be.instanceof(Buffer)
          expect(data.toString()).to.be.eql(msgText)
          reqSocket.close()
          repSocket.close()
          server.close()
          done()

        # send out the initial request message
        reqSocket.send msgText    

  it 'should queue up the requests if no reply send back', (done) ->
    replyCount = 0
    replyMsgCount = 0
    requestCount = 0
    requestMsgCount = 0

    # create the reply server socket
    repSocket = serverContext.socket SocketMQ.REP
    
    # handle message
    repSocket.on 'message', (data) ->
      expect(data).to.be.instanceof(Buffer)
      expect(data.toString()).to.be.eql(msgText)
      # we don't reply to the request
      replyMsgCount++   
      
    # bind reply socket to specified endpoint
    repSocket.bind 'smq://echo', (err) ->
      if err then throw err
      
      # create the request socket and connect
      reqSocket = SocketMQ.connect('http://127.0.0.1:8888').socket(SocketMQ.REQ)
      reqSocket.connect 'smq://echo'
      
      # handle message
      reqSocket.on 'message', (data) ->
        expect(data).to.be.instanceof(Buffer)
        expect(data.toString()).to.be.eql(msgText)
        requestMsgCount++
      
      send = () ->
        reqSocket.send msgText
        requestCount++

      # send out 10 messages  
      send msg for msg in [10..1]

      setTimeout () ->
        expect(replyCount).to.eql(0)
        expect(replyMsgCount).to.eql(1)        
        expect(requestCount).to.eql(10)
        expect(requestMsgCount).to.eql(0)
        # now let's send back the reply
        reply = () ->
          reqSocket.send msgText
          replyCount++
        reply msg for msg in [10..1]

        setTimeout () ->
          expect(replyCount).to.eql(10)
          expect(replyMsgCount).to.eql(10)        
          expect(requestCount).to.eql(10)
          expect(requestMsgCount).to.eql(10)
          reqSocket.close()
          repSocket.close()
          server.close()
          done()
        , 2000

      , 2000

    