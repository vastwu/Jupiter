http = require 'http'
Path = require 'path'
fs = require 'fs'
URL = require 'url'
express = require "express"
bodyParser = require 'body-parser'
coffeescript = require 'coffee-script'
UglifyJS = require 'uglify-js'
# 子模块
report = require "./report"


IS_DEBUG = process.env.NODE_ENV is 'development'

# 常量
PORT = process.env.PORT

log = ()->
  return console.log.apply console, arguments

app = express()


jsonOutput = (data) ->
  str = JSON.stringify data
  @writeHead 200,
    'Content-Type': 'text/json'
  @end str

app.use (req, res, next)->
  url = URL.parse req.url, true
  req.url = url
  next()

app.get '/favicon.ico', (req, res, next)->
  res.end('')

app.use bodyParser.urlencoded
  extended: true
  limit: '10mb'

app.use bodyParser.json()

report app

app.use (req, res, next) ->

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


app.listen(PORT)


console.log "Server running at http://127.0.0.1:#{PORT}"
