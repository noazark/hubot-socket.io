{Adapter,TextMessage,ObjectMessage} = require 'hubot'

port = parseInt process.env.PORT or 9090
origins = process.env.HUBOT_SOCKETIO_ORIGINS or '*:*'

io = require('socket.io').listen port

if process.env.HEROKU_URL
  io.configure ->
    io.set "origins", origins
    io.set "transports", ["xhr-polling"]
    io.set "polling-duration", 10

class SocketIO extends Adapter

  constructor: (@robot) ->
    @sockets = {}
    super @robot

  send: (envelope, strings...) ->
    socket = @sockets[envelope.user.id]
    if typeof envelope.message.text == "string"
      socket.emit 'message', str for str in strings
    else
      socket.emit 'message', {response: str, requestId: envelope.message.id} for str in strings

  reply: (envelope, strings...) ->
    socket = @sockets[envelope.user.id]
    for str in strings
      socket.emit 'message', "#{user.name}: #{str}"

  run: ->
    io.sockets.on 'connection', (socket) =>
      @sockets[socket.id] = socket

      socket.on 'message', (message) =>
        user = @userForId socket.id, name: 'Try Hubot', room: socket.id
        if typeof message == "string"
          @receive new TextMessage(user, message)
        else
          @receive new ObjectMessage(user, message, message.id)

      socket.on 'disconnect', =>
        delete @sockets[socket.id]

    @emit 'connected'

exports.use = (robot) ->
  new SocketIO robot
