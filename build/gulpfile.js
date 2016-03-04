var gulp = require('gulp');
var rsync = require('gulp-rsync');

// 上线预发布环境文件
gulp.task('deploy', function() {
  var deployList = [
    // 一般情况下该目录无需重复部署
    //'../node_modules/**',
    '../lib/**',
    '../app.js',
    '../processes.json'
  ]
  return gulp.src(deployList).pipe(rsync({
    hostname: '10.101.1.97',
    username: 'worker',
    root: '../',
    destination: '~/tags.yidianzixun.com'
  }))
});



gulp.task('build', ['compiler_coffee'], function() {
  console.log('build start');
});
