{expect} = require 'chai'
SocketMQ = require '../'


describe 'SocketMQ', () ->
  it 'should expose version number', () ->
    expect(SocketMQ.version).to.match(/^\d+\.\d+\.\d+$/)

  it 'should expose the Context constructor function', () ->
    expect(SocketMQ.Context).to.be.a('function')

  it 'should expose the Socket constructor function', () ->
    expect(SocketMQ.Socket).to.be.a('function')

  it 'should expose the listen function', () ->
      expect(SocketMQ.listen).to.be.a('function')

  it 'should expose the connect function', () ->
      expect(SocketMQ.connect).to.be.a('function')    

  it 'should expose the proxy function', () ->
    expect(SocketMQ.proxy).to.be.a('function')

  it 'should expose socket types as number', () ->
    ['PAIR', 'REQ', 'REP', 'DEALER', 'ROUTER', 'PUB', 'SUB', 'PUSH', 'PULL'].forEach (socketType) ->
      expect(SocketMQ[socketType]).to.be.a('number')