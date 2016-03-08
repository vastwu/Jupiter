
# 导出基类
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
      @autoFlush yes

  autoFlush: (enable)->
    clearInterval @autoFlushTimer
    if enable
      @autoFlushTimer = setInterval ()=>
        @flush()
      , @AUTO_FLUSH_TIMER

  # 输出实现，目前为文件系统方式
  flush: ()->
    throw new Error('flush must be implement')

module.exports = LogExportor
