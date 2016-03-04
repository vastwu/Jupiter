var gulp = require('gulp');
var coffee = require('gulp-coffee');
var stylus = require('gulp-stylus');

var COFFEE_SRC = 'lib/**/*.coffee'
var STYLU_SRC = 'lib/**/*.styl'
var LIB_SRC = 'lib/**/*.*'
var DEST_SRC = 'src'

var compileCoffee = function() {
  gulp.src(COFFEE_SRC)
    .pipe(coffee())
    .pipe(gulp.dest(DEST_SRC));
}
var compileStylu = function() {
  gulp.src(STYLU_SRC)
    .pipe(stylus())
    .pipe(gulp.dest(DEST_SRC));
}

gulp.task('c-coffee', compileCoffee)
gulp.task('c-stylus', compileStylu)


gulp.task('watch', function() {
  compileStylu();
  compileCoffee();
  var watcher = gulp.watch(LIB_SRC, ['c-coffee', 'c-stylus']);
  watcher.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });
  /*
  var cw = gulp.watch(COFFEE_SRC, ['c-coffee']);
  var sw = gulp.watch(STYLU_SRC, ['c-stylus']);
  cw.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });
  sw.on('change', function(event) {
    console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
  });
  */
});
