fs = require 'fs'
http = require 'http'
redis = require 'redis'
Path = require 'path'
LogExportor = require './LogExportor2'
Transform = require('stream').Transform

SOCKET_PORT = 3000
logExportors = {}

DEFAULT_CONFIG =
  connection: no
  receiving: yes
  appCode: '*'
  filter: ''

# 深拷贝
copy = (source) ->
  r = {}
  for k, v of source
    if typeof v is 'object'
      r[k] = copy v
    else
      r[k] = v
  return r

###
client = redis.createClient 6379,'127.0.0.1', {}

client.on "error",  (err) ->
  console.log "Error " + err
###

io = null
SocketManager = (port)->
  self = this
  socketServer = http.createServer()
  io = require('socket.io') socketServer
  io.on 'connection', (socket) ->
    console.log 'connected!!!!!!!'
    socket.on 'event', (data) ->
      console.log '--------------------!!!!!!!!!!'
    socket.on 'config', (data) ->
      self.setConfig socket, data
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

manageInstance = null
module.exports = (req, res) ->
  switch req.url.pathname
    when '/status'
      res.json
        status: 200
        enable: if manageInstance then '1' else '0'
        socketPort: SOCKET_PORT
        defaultConfig: DEFAULT_CONFIG

    when '/start'
      if not manageInstance
        manageInstance = new SocketManager SOCKET_PORT
        res.json
          status: 200
          socketPort: SOCKET_PORT
      else
        res.json
          status: 500
          reason: "socket is listening #{SOCKET_PORT}"
          socketPort: SOCKET_PORT
    when '/stop'
      # 停止接收
      manageInstance.close()
      manageInstance = null
      res.end 'ok'
      return
    when '/send'
      res.end('')
      if not manageInstance
        return
      args = copy req.url.query

      if args.content
        # content中可能携带类似 [33m一类的颜色字符
        args.content = args.content.replace(/\[\d*m/g,'')

      args.ua = req.headers['user-agent'] or ''
      args.host = req.headers['host'] or ''
      args.cookie = req.headers.cookie or ''
      args.date = Date.now()

      manageInstance.boardcast 'log', args

      # 先不做存储 
      appCode = args.appCode
      if not appCode
        throw new Error 'missing app code'

      exportor = logExportors[appCode]
      if not exportor
        exportor = logExportors[appCode] = new LogExportor appCode
        exportor.autoFlush yes

      exportor.push args

    when '/index'

      # 首页
      filePath = "lib/client/report/index.html"
      html = fs.readFileSync filePath, 'utf-8'
      res.end html
    when '/get'
      filePath = "logs/app.3.20160114"
      logs = fs.readFileSync filePath, 'utf-8'
      logs = logs.split '\n'
      logs = (JSON.parse(item) for item in logs when item)
      res.json
        status: 0
        result: logs
