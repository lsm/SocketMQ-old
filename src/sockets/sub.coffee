{Socket, types} = require './socket'
debug = require('debug')('socketmq:sub')


class SubSocket extends Socket

  constructor: (context, options) ->
    super context, 'sub', options
    @subscriptions = []

  subscribe: (topic) ->
    topic = '^' + topic
    @subscriptions.push(new RegExp(topic))

  handleMessage: (conn, data) ->
    if @subscriptions.length > 0
      @subscriptions.some (sub) =>
        if sub.test data
          @emit 'message', data
          return true
    return @

module.exports = SubSocket
