define(function (require){
  var EditorX = require('./src/index')

  var editorX = new EditorX()

  editorX.ready = function () {
    //editorX.setContent new Array(20).join('一二三四五六七八九十')
    editorX.addPlugin({
      type: EditorX.TYPE_RANGE,
      name: 'H1'
    })

    editorX.addPlugin({
      type: EditorX.TYPE_PARAGRAPY,
      name: 'image'
    });
  }

  window.doAction = function(){
    editorX.insert('123')
  }
});
