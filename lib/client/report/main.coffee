
socket = null
configJson = null
startService = (cb)->
  $.get '/start', cb

closeService = ()->
  if not socket
    return
  socket.close()
  $.get '/stop', ()->
    $('#statusFlag').attr 'class', 'glyphicon glyphicon-remove-sign text-danger'

connectSocket = (cb)->
  src = "#{HOST_NAME}:#{result.socketPort}/socket.io/socket.io.js"

loadScript = (src, args = [])->
  return new Promise (resolve, reject)->
    s = document.createElement 'script'
    s.src = src
    s.onload = ()->
      resolve args
    document.body.appendChild s

# render status
statusChange = (config)->
  TRUE_ICON = "<i class='glyphicon glyphicon-ok-sign text-success'></i>"
  FALSE_ICON = "<i class='glyphicon glyphicon-remove-sign text-danger'></i>"
  DEFAULT_ICON = "<i class='glyphicon glyphicon-question-sign text-warning'></i>"

  html = []
  for key, value of config
    switch value
      when yes
        value = TRUE_ICON
      when no
        value = FALSE_ICON

    html.push "
      <div class='row'>
        <label class='col-sm-6'>#{key}：</label> 
        <div class='col-sm-6'>#{value}</div> 
      </div> 
    "
  $('.status-win').html html.join('')


tryConnection = () ->
  HOST_NAME ="http://#{location.hostname}"
  $.get '/status', (result)->
    if result.status is 200 and result.enable is '1'
      src = "#{HOST_NAME}:#{result.socketPort}/socket.io/socket.io.js"
      configJson = result.defaultConfig
      configJson.connection = yes
      loadScript(src).then ()->
        socket = io "#{HOST_NAME}:#{result.socketPort}",
          reconnection: no

        for evt, listener of socketImplement
          socket.on evt, do (listener)->
            ()->
              listener.apply(socket, arguments)

    else
      if not configJson
        configJson = {}
      configJson.connection = yes
      socketImplement.connect_error.apply null, []

$('#toggleSocket').click ()->
  if configJson.connection
    closeService()
  else
    startService tryConnection

$('#toggleReceiving').change ()->
  configJson.receiving = this.checked
  socketImplement.setConfig configJson

$('#saveAppcodeFilter').click ()->
  value = $(this).parents('.form-group').find('input').val()
  configJson.appCode = value
  socketImplement.setConfig configJson


$('#saveContentFilter').click ()->
  value = $(this).parents('.form-group').find('input').val()
  configJson.filter = value
  socketImplement.setConfig configJson


renderer = (item)->
  dateString = new Date(item.date).toLocaleString()
  row =
    "<div class='item'>
      <div class='row'>
        <div class='col-md-4'>#{dateString}</div> 
        <div class='col-md-4'>#{item.host}</div> 
        <div class='col-md-4'>#{item.ua}</div> 
      </div>
      <div class='row log #{item.type}'>
        <div class='col-md-12'>
          <pre><b class='text-primary'>[#{item.appCode}]</b>#{item.content}</pre>
        </div>
      </div>
    </div>"
  return row

socketImplement =
  setConfig: (json)->
    socket.emit 'config', json
    statusChange json

  connect: ()->
    console.log 'connect'
    $('#statusFlag').attr 'class', 'glyphicon glyphicon-ok-sign text-success'
    configJson.connection = yes
    socketImplement.setConfig configJson

  error: (message)->
    alert message

  event: (data)->
    console.log data

  log: (item)->
    row = renderer item
    $tb = $('#logTableBody')
    firstChild = $tb.children()[0]
    if firstChild
      $(firstChild).before row
    else
      $tb.append row

  disconnect: ()->
    configJson.connection = no
    statusChange configJson

  connect_error: ()->
    console.log 'error'
    configJson.connection = no
    statusChange configJson

  reconnect_error: ()->
    console.log 'error'
    configJson.connection = no
    statusChange configJson
    # 尝试重启
    #$.get '/start'


$ ()->
  tryConnection()



