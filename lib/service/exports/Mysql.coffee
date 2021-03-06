fs = require 'fs'
mysql = require 'mysql'
Exportor = require './Exportor'
config = require '../config'

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
    @MAX_LENGTH = 200
    @ONCE_FLUSH_COUNT = 100
    # 10m 一次入数据库
    @AUTO_FLUSH_TIMER = 1000 * 10 * 60
    #@AUTO_FLUSH_TIMER = 5000
    @sqlPool = mysql.createPool config.logSqlOptions
    return

  flush: ()->
    if @length is 0
      return
    if @pause is yes
      return
    @pause = yes
    tableName = "mp_logs_#{@appCode}"
    sql = "insert into #{tableName} (appcode, content, type, date, ua, host) values "
    insertString = for item in @pool.splice 0, @ONCE_FLUSH_COUNT
      #parseLog2String item
      "(\"#{item.appCode}\", \"#{item.content.replace(/'"/g, "'")}\", \"#{item.type}\", \"#{item.date}\", \"#{item.ua}\", \"#{item.host}\")"
    sql = sql + insertString
    sql = mysql.format sql
    self = @

    sqlPool = @sqlPool
    tableCheckerSql = "create table if not exists #{tableName} like mp_logs_debug;"
    sqlPool.query tableCheckerSql, (err, result, fields) ->
      sqlPool.query sql, (err, result, fields) ->
        time = new Date().toLocaleString()
        if err
          console.log "#{time}: #{err}\n #{sql}"
        else
          console.log "#{time}: #{result.message}"
        length = self.length -= insertString.length
        self.pause = no
        if length > 0
          console.log "last #{length} in queue..."
        else
          console.log "queue has clean! #{length}"
    return

module.exports = MysqlExportor
