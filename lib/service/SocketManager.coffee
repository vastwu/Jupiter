http = require 'http'
socketIO = require('socket.io')

module.exports = SocketManager = (port)->
  self = this
  socketServer = http.createServer()
  io = socketIO socketServer
  io.on 'connection', (socket) ->
    console.log 'connected!!!!!!!'
    socket.on 'event', (data) ->
      console.log '--------------------!!!!!!!!!!'

    socket.on 'config', (data) ->
      self.setConfig this, data

    socket.on 'disconnect', ()->
      console.log '--------------------lost'

    socket.emit 'event', 'welcome'
  socketServer.listen port
  console.log "--socket run on #{port}"

  configs = {}
  @setConfig = (socket, data)->
    console.log 'set config', data
    if data.filter
      try
        data.filterReg = new RegExp data.filter
      catch err
        socket.emit 'error', 'parse config.filter Error!'

    socket.$config = data
    configs[socket.id] = data

  @getConfig = (socket)->
    return configs[socket.id] or DEFAULT_CONFIG

  @close = ()->
    io.close()
    clients = []

  @isSending = (socket, args)->
    config = @getConfig socket

    if config.receiving isnt yes
      return false
    if config.appCode isnt '*' and config.appCode isnt args.appCode
      return false
    if config.filterReg and config.filterReg.test(args.content) is false
      return false

    return yes

  @boardcast = (evt, args)->
    self = @
    sockets = io.sockets.sockets
    for id, socket of sockets
      if @isSending(socket, args) is yes
        socket.emit evt, args
  return