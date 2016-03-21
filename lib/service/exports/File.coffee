util = require 'util'
fs = require 'fs'
Exportor = require './Exportor'

LOG_FILE_PATH = process.cwd() + '/logs'

parseLog2String = (log) ->
  str = JSON.stringify(log)
  return str

getDateString = (date = new Date())->
  m = date.getMonth() + 1
  d = date.getDate()
  if m < 10
    m = "0#{m}"
  if d < 10
    d = "0#{d}"
  return "#{date.getFullYear()}#{m}#{d}"

# 导出日志
class FileExportor extends Exportor
  constructor: (@appCode)->
    Exportor.call @, @appCode
    @MAX_LENGTH = 800
    @ONCE_FLUSH_COUNT = 800
    # 10m 一次导出
    @AUTO_FLUSH_TIMER = 1000 * 10 * 60
    return
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

module.exports = FileExportor
