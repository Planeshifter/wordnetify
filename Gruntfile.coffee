module.exports = (grunt) ->
  grunt.initConfig
    watch:
      files: ['src/*.coffee'],
      tasks: 'coffee:build'
    coffee:
      build:
        options:
          sourceMap: true
        expand: true,
        cwd: "#{__dirname}/src/",
        src: [ '**/*.coffee', '!**/wordnetify.coffee' ],
        dest: 'lib',
        ext:  '.js'
      compileMain:
        options:
          bare: true,
        files:
          'lib/wordnetify.js': 'src/wordnetify.coffee',

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.registerTask 'default', ['coffee']
