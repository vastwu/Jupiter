fs = require 'fs'
redis = require 'redis'
Path = require 'path'
LogExportor = require './LogExportor2'
SocketManager = require './SocketManager'
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
getParams = (req, keys)->
  body = req.body or {}
  query = req.query or {}

  result = for key in keys
    body[key] or query[key]
  return result

manageInstance = null

module.exports = (app) ->
  app.get '/status', (req, res)->
    res.json
      status: 200
      enable: if manageInstance then '1' else '0'
      socketPort: SOCKET_PORT
      defaultConfig: DEFAULT_CONFIG

  app.get '/start', (req, res)->
    if not manageInstance
      manageInstance = new SocketManager SOCKET_PORT
      res.json
        status: 200
        socketPort: SOCKET_PORT
        defaultConfig: DEFAULT_CONFIG
    else
      res.json
        status: 500
        reason: "socket is listening #{SOCKET_PORT}"
        socketPort: SOCKET_PORT
    
  
  app.get '/stop', (req, res)->
    # 停止接收
    manageInstance.close()
    manageInstance = null
    res.end 'ok'

  sendRouter = (req, res)->
    res.end('')
    if not manageInstance
      return

    args = {}
    appCode = req.url.query.appCode
    if not appCode
      throw new Error 'missing app code'

    [content, type] = getParams req, ['content', 'type']
  
    content = decodeURIComponent content
    content = (content or '').replace(/\[\d*m/g,'')

    args.appCode = appCode
    args.content = content
    args.type = type
    args.ua = req.headers['user-agent'] or ''
    args.host = req.headers['host'] or ''
    args.cookie = req.headers.cookie or ''
    args.date = Date.now()

    manageInstance.boardcast 'log', args

    # 先不做存储 

    exportor = logExportors[appCode]
    if not exportor
      exportor = logExportors[appCode] = new LogExportor appCode
      exportor.autoFlush yes

    exportor.push args


  app.get '/send', sendRouter
  app.post '/send', sendRouter

  app.get '/index', (req, res)->
    # 首页
    filePath = "lib/client/report/index.html"
    html = fs.readFileSync filePath, 'utf-8'
    res.end html

  app.get '/get', (req, res)->
    filePath = "logs/app.3.20160114"
    logs = fs.readFileSync filePath, 'utf-8'
    logs = logs.split '\n'
    logs = (JSON.parse(item) for item in logs when item)
    res.json
      status: 0
      result: logs


