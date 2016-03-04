define ()->
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
