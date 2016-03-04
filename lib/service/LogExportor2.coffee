fs = require 'fs'

CWD = process.cwd()
LOG_FILE_PATH = CWD + '/logs'

# 深拷贝
copy = (source) ->
  r = {}
  for k, v of source
    if typeof v is 'object'
      r[k] = copy v
    else
      r[k] = v
  return r

parseLog2String = (log) ->
  str = JSON.stringify(log)
  return str

getDateString = (date = new Date())->
  m = date.getMonth()
  d = date.getDate()
  if m < 10
    m = "0#{m}"
  if d < 10
    d = "0#{d}"
  return "#{date.getFullYear()}#{m}#{d}"

# 导出日志
class LogExportor
  constructor: (@appCode)->
    @pool = []
    @length = 0
    @autoFlushTimer = 0
    # 最大长度，超过后强制触发flush
    @MAX_LENGTH = 30
    # 轮询flush时间间隔
    @AUTO_FLUSH_TIMER = 5000
    # 单次输出log条数上限
    @ONCE_FLUSH_COUNT = 30

  push: (obj)->
    @pool.push obj
    @length++
    if @length > @MAX_LENGTH
      @flush()
      @autoFlushTimer yes

  autoFlush: (enable)->
    clearInterval @autoFlushTimer
    if enable
      @autoFlushTimer = setInterval ()=>
        @flush()
      , @AUTO_FLUSH_TIMER

  # 输出实现，目前为文件系统方式
  flush: ()->
    if @length is 0
      return
    insertString = for item in @pool.splice 0, @ONCE_FLUSH_COUNT
      parseLog2String item
    @length -= insertString.length
    if @length > 0
      console.log "last #{@length} in queue..."
    else
      console.log "queue has clean! #{@length}"

    today = new Date()
    fileName = "#{LOG_FILE_PATH}/app.#{@appCode}.#{getDateString(today)}"
    insertString = insertString.join('\n') + '\n'

    writeStream = fs.createWriteStream fileName,
      flags: 'a'

    writeStream.write insertString
    writeStream.end()

module.exports = LogExportor
