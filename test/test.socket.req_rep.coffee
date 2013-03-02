{expect} = require 'chai'
SocketMQ = require '../'
http = require 'http'


describe 'SocketMQ.socket REQ/REP', () ->

  msgText = 'hello'

  it 'should bind on reply socket and get echo message from it', (done) ->
    serverContext = SocketMQ.listen 8889, '127.0.0.1'
    # create the reply server socket
    repSocket = serverContext.socket 'rep'

    # handle message
    repSocket.on 'message', (data, reply) ->
      expect(data).to.be.eql(msgText)
      reply data

    # bind reply socket to specified endpoint
    repSocket.bind 'smq://echo', (err) ->
      if err then throw err
      clientContext = SocketMQ.connect('http://127.0.0.1:8889')

      # create the request socket and connect
      reqSocket = clientContext.socket 'req'
      reqSocket.connect 'smq://echo'

      # handle message
      reqSocket.on 'message', (data) ->
        expect(data).to.be.eql(msgText)
        clientContext.close()
        serverContext.close()
        done()

      # send out the initial request message
      reqSocket.send msgText

  it 'should bind on request socket send and get multiple messages', (done) ->
    serverContext = SocketMQ.listen 8899, '127.0.0.1'
    # create the request spcket
    reqSocket = serverContext.socket 'req'

    # counters
    reqCount = 0
    repCount = 0

    # bind request socket to specified endpoint
    reqSocket.bind 'smq://echo', (err) ->
      if err then throw err

      clientContext = SocketMQ.connect('http://127.0.0.1:8899')
      # create the reply client socket
      repSocket = clientContext.socket 'rep'
      # connect the reply socket
      repSocket.connect 'smq://echo'

      # handle message
      repSocket.on 'message', (data, reply) ->
        expect(data).to.be.eql(msgText)
        repCount++
        reply data

      reqSocket.on 'message', (data) ->
        expect(data).to.be.eql(msgText)
        if reqCount++ is 10
          expect(repCount).to.be.eql(10)
          clientContext.close()
          serverContext.close()
          done()
        else
          reqSocket.send data

      # send out the initial request message
      reqSocket.send msgText
      reqCount++

  it 'should queue up the requests if no reply send back', (done) ->
    replyCount = 0
    replyMsgCount = 0
    requestCount = 0
    requestMsgCount = 0

    serverContext = SocketMQ.listen 8999, '127.0.0.1'
    # create the reply server socket
    repSocket = serverContext.socket 'rep'

    replyFn = null
    # handle message
    repSocket.on 'message', (data, reply) ->
      expect(data).to.be.eql(msgText)
      # we don't reply to the request
      replyMsgCount++

      _reply = () ->
        replyCount++
        reply data

      replyFn = _reply

    # bind reply socket to specified endpoint
    repSocket.bind 'smq://echo', (err) ->
      if err then throw err

      # create the request socket and connect
      reqSocket = SocketMQ.connect('http://127.0.0.1:8999').socket 'req'
      reqSocket.connect 'smq://echo'

      # handle message
      reqSocket.on 'message', (data) ->
        expect(data).to.be.eql(msgText)
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
        replyFn()

        setTimeout () ->
          expect(replyCount).to.eql(1)
          expect(replyMsgCount).to.eql(2)
          expect(requestCount).to.eql(10)
          expect(requestMsgCount).to.eql(1)
          reqSocket.close()
          serverContext.close()
          done()
        , 500

      , 500
