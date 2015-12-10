module.exports = (grunt) =>
  grunt.initConfig
    coffee:
      compile:
        files: [
          {expand: true, cwd: 'src', src: '*.coffee', dest: 'lib/', ext: '.js'}
        ]
    concat:
      dist:
         src: [ 'lib/*.js' ]
         dest: 'lib/shipit.js'
    mochaTest:
      options:
        reporter: 'spec'
      src: ['test/*.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-contrib-concat'

  grunt.registerTask 'default', ['coffee', 'mochaTest']
