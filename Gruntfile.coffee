module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      build:
        options:
          sourceMap: true
        expand: true,
        cwd: 'src',
        src: [ '**/*.coffee' ],
        dest: 'lib',
        ext:  '.js'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.registerTask 'default', ['coffee']
