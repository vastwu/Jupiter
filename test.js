var Transform = require('stream').Transform;
var Util = require('util')



var MyTransform = function () {
  Transform.call(this, {
    objectMode: true
  })
  this._cache = []
}
Util.inherits(MyTransform, Transform)

MyTransform.prototype._write = function (data, encoding, done) {
  console.log('write', data)
  var cache = this._cache
  cache.push(data)
  if (cache.length >= 5) {
    this.push(cache.slice(0))
    this._cache = []
  }
  done()
}

/*
var s = new Transform({
  nouse_transform: function (data, encoding, done) {
    var cache = []
    cache.push(data);
    console.log('transform', data);
    if (cache.length >= 10) {
      done(null, data);
    }
  },
  read: function (size) {
    console.log('read...', this._buffer)
  },
  write: function (data, encoding, done) {
    console.log('write', data)
    cache.push(data)
    if (cache.length >= 5) {
      this.push(cache.slice(0))
      cache = []
    }
    done()
  },
  nouse_flush: function (done) {
    console.log('flush')
    done()
  }
})
*/

s = new MyTransform()

var writeInToStream = function () {
  console.log('write!!!!')
  s.write({
    text: Date.now()
  })
  // 300 - 600
  setTimeout(writeInToStream, Math.random() * 300 + 300)
}

setTimeout(writeInToStream, 500)
console.log('---------------------------start------------------------------')

/*
s.on('readable', function () {
  console.log('readable', s.read())
})
*/

setInterval(function () {
  var one = s.read(1)
  console.log('----------read out:', one)
}, 2000)
