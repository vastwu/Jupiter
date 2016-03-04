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
  format = copy log
  str = JSON.stringify(format)
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
    @uniques = {}
    @pool = []
    @length = 0
    @autoFlushTimer = 0
    # 最大长度，超过后强制触发flush
    @MAX_LENGTH = 30
    # 轮询flush时间间隔
    @AUTO_FLUSH_TIMER = 5000
    # 单次输出log条数上限
    @ONCE_FLUSH_COUNT = 30
    # 带有唯一key的 log 收集上限
    @UNIQUE_MAX_LENGTH = 60
    # 唯一key收集上限后的清理间隔
    @UNIQUE_CLEAR_DURATION = 60000

  push: (obj, unique)->
    if unique
      uniqueValue = @uniques[unique]
      if not uniqueValue or uniqueValue is 0
        # 没有收集该值，初始化
        @uniques[unique] = 1
      else if uniqueValue > @UNIQUE_MAX_LENGTH
        # 超过上限，停止收集
        return
      else
        # 正常收集
        uniqueValue++
        @uniques[unique] = uniqueValue
        if uniqueValue > @UNIQUE_MAX_LENGTH
          # 收集达到阈值后，定时清理, 仅在最后一次正常收集时触发
          @clearUniqueValue unique

    @pool.push obj
    @length++
    if @length > @MAX_LENGTH
      @flush()

  clearUniqueValue: (key)->
    setTimeout ()=>
      @uniques[key] = 0
    , @UNIQUE_CLEAR_DURATION

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
      console.log "queue has clean!"

    today = new Date()
    fileName = "#{LOG_FILE_PATH}/app.#{@appCode}.#{getDateString(today)}"
    insertString = insertString.join('\n') + '\n'
    fs.appendFile fileName, insertString, (err) ->
      if err
        throw err
      console.log 'The "data to append" was appended to file!'


module.exports = LogExportor
