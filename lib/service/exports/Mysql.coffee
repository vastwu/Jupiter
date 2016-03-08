fs = require 'fs'
mysql = require 'mysql'
Exportor = require './Exportor'

LOG_FILE_PATH = process.cwd() + '/logs'

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
class MysqlExportor extends Exportor
  # 输出实现，目前为文件系统方式
  constructor: (@appCode)->
    @pause = no
    Exportor.call @, @appCode
    logSqlOptions =
      connectionLimit: 10
    @sqlPool = mysql.createPool logSqlOptions

  flush: ()->
    if @length is 0
      return
    if @pause is yes
      return
    @pause = yes
    sql = "insert into mp_logs (appcode, content, type, date, ua, host) values "
    insertString = for item in @pool.splice 0, @ONCE_FLUSH_COUNT
      #parseLog2String item
      "('#{item.appCode}', '#{item.content}', '#{item.type}', '#{item.date}', '#{item.ua}', '#{item.host}')"
    sql = sql + insertString
    self = @
    @sqlPool.query sql, (err, result, fields) ->
      console.log err, result
      length = self.length -= insertString.length
      self.pause = no
      if length > 0
        console.log "last #{length} in queue..."
      else
        console.log "queue has clean! #{length}"
    return

module.exports = MysqlExportor
