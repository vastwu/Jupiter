
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

tryConnection = () ->
  HOST_NAME ="http://#{location.hostname}"
  $.get '/status', (result)->
    if result.status is 200 and result.enable is '1'
      src = "#{HOST_NAME}:#{result.socketPort}/socket.io/socket.io.js"
      configJson = result.defaultConfig
      loadScript(src).then ()->
        socket = io "#{HOST_NAME}:#{result.socketPort}",
          reconnection: no

        for evt, listener of socketImplement
          socket.on evt, do (listener)->
            ()->
              listener.apply(socket, arguments)

    else
      socketImplement.connect_error.apply null, []


$("#startSocket").click ()->
  startService tryConnection

$("#stopSocket").click ()->
  closeService()

$('#toggleReceiving').change ()->
  configJson.receiving = this.checked
  if configJson.receiving
    $('#statusLog').attr 'class', 'glyphicon glyphicon-ok-sign text-success'
  else
    $('#statusLog').attr 'class', 'glyphicon glyphicon-remove-sign text-danger'
  socket.emit 'config', configJson

$('#saveAppcodeFilter').click ()->
  appCode = $(this).prev().val()
  configJson.appCode = appCode
  socket.emit 'config', configJson
  $('#appCodeValue').html appCode


$('#saveContentFilter').click ()->
  filter = $(this).prev().val()
  configJson.filter = filter
  socket.emit 'config', configJson
  $('#contentFilterValue').html filter


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
          <pre>#{item.content.replace(/\[\d*m/g,'')}</pre>
        </div>
      </div>
    </div>"
  return row

socketImplement =
  connect: ()->
    console.log 'connect'
    $('#statusFlag').attr 'class', 'glyphicon glyphicon-ok-sign text-success'
    socket.emit 'config', configJson

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

  disConnect: ()->
    $('#statusFlag').attr 'class', 'glyphicon glyphicon-remove-sign text-danger'

  connect_error: ()->
    console.log 'error'
    $('#statusFlag').attr 'class', 'glyphicon glyphicon-remove-sign text-danger'

  reconnect_error: ()->
    console.log 'error'
    $('#statusFlag').attr 'class', 'glyphicon glyphicon-remove-sign text-danger'
    # 尝试重启
    #$.get '/start'


$ ()->
  tryConnection()



