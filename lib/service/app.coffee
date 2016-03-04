http = require 'http'
Path = require 'path'
fs = require 'fs'
URL = require 'url'
coffeescript = require 'coffee-script'
UglifyJS = require 'uglify-js'
# 子模块
report = require "./report"

IS_DEBUG = process.env.NODE_ENV is 'development'

# 常量
PORT = process.env.PORT

log = ()->
  return console.log.apply console, arguments

jsonOutput = (data) ->
  str = JSON.stringify data
  @writeHead 200,
    'Content-Type': 'text/json'
  @end str

# 扩展res && req
addExtend = (req, res) ->
  url = URL.parse req.url, true
  req.url = url
  res.json = jsonOutput


onRequest = (req, res) ->
  addExtend req, res
  url = req.url
  if url.path is '/favicon.ico'
    res.end ''
    return
  try
    report req, res
    if not res.finished
      # static
      ext = Path.extname req.url.pathname
      fileName = req.url.pathname.replace('.js', '.coffee')
      filePath = "lib/client/#{fileName}"

      if not fs.existsSync filePath
        throw new Error "#{fileName} not found"

      if Path.extname(fileName) is '.coffee'
        cont = fs.readFileSync filePath, 'utf-8'
        cont = coffeescript.compile cont
        if not IS_DEBUG
          # 非debug需要压缩
          result = UglifyJS.minify cont,
            fromString: true
          cont = result.code
        res.writeHead 200,
          "Content-Type": "text/javascript"
        res.end cont
      else
        fs.createReadStream(filePath).pipe res

  catch e
    log e
    res.statusCode = 503
    res.end e.toString()

app = http.createServer onRequest
app.listen PORT


console.log "Server running at http://127.0.0.1:#{PORT}"
