{expect} = require 'chai'
SocketMQ = require '../'
http = require 'http'


describe 'SocketMQ PUB/SUB sockets', () ->

  msgText = 'hello'

  it 'should bind on sub socket and get message from pub socket', (done) ->
    serverContext = SocketMQ.listen 8988, '127.0.0.1'
    # create the sub server socket
    subSocket = serverContext.socket 'sub'

    subSocket.subscribe 'hel'

    # handle message
    subSocket.on 'message', (data) ->
      expect(data).to.be.eql(msgText)
      done()

    # bind sub socket to specified endpoint
    subSocket.bind 'smq://pubsub', (err) ->
      if err then throw err
      clientContext = SocketMQ.connect('http://127.0.0.1:8988')

      # create the pub socket and connect
      pubSocket = clientContext.socket 'pub'
      pubSocket.connect 'smq://pubsub'

      # send out the pub message
      pubSocket.on 'connect', () ->
        pubSocket.send msgText


  it 'should bind on pub socket and send multiple messages to sub socket', (done) ->
    serverContext = SocketMQ.listen 8989, '127.0.0.1'
    # create the pub spcket
    pubSocket = serverContext.socket 'pub'

    # counters
    subCount = 0

    # bind pub socket to specified endpoint
    pubSocket.bind 'smq://pubsub', (err) ->
      if err then throw err

      clientContext = SocketMQ.connect('http://127.0.0.1:8989')
      # create the sub client socket
      subSocket = clientContext.socket 'sub'
      # connect the sub socket
      subSocket.connect 'smq://pubsub'

      subSocket.subscribe 'h'

      # handle message
      subSocket.on 'message', (data) ->
        expect(data).to.be.eql(msgText)
        subCount++
        if subCount is 10
          done()

      pubSocket.on 'connect', () ->
        for i in [0..10]
          pubSocket.send msgText

