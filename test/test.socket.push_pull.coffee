{expect} = require 'chai'
SocketMQ = require '../'
http = require 'http'


describe 'SocketMQ PUSH/PULL sockets', () ->

  msgText = 'hello'

  it 'should bind on pull socket and get message from push socket', (done) ->
    serverContext = SocketMQ.listen 8998, '127.0.0.1'
    # create the pull server socket
    pullSocket = serverContext.socket 'pull'

    # handle message
    pullSocket.on 'message', (data) ->
      expect(data).to.be.eql(msgText)
      done()

    # bind pull socket to specified endpoint
    pullSocket.bind 'smq://pushpull', (err) ->
      if err then throw err
      clientContext = SocketMQ.connect('http://127.0.0.1:8998')

      # create the push socket and connect
      pushSocket = clientContext.socket 'push'
      pushSocket.connect 'smq://pushpull'

      # send out the push message
      pushSocket.on 'connect', () ->
        pushSocket.send msgText


  it 'should bind on push socket and send multiple messages to pull socket', (done) ->
    serverContext = SocketMQ.listen 9998, '127.0.0.1'
    # create the push spcket
    pushSocket = serverContext.socket 'push'

    # counters
    pullCount = 0

    # bind push socket to specified endpoint
    pushSocket.bind 'smq://pushpull', (err) ->
      if err then throw err
      clientContext = SocketMQ.connect('http://127.0.0.1:9998')

      pullSocket = clientContext.socket 'pull'
      pullSocket.connect 'smq://pushpull'

      pullCount = 0

      pullSocket.on 'message', (data) ->
        expect(data).to.be.eql(msgText)
        if pullCount++ is 3
          done()

      for i in [0..3]
        pushSocket.send msgText

