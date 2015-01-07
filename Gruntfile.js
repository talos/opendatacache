module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    uglify: {
      options: {
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      },
      build: {
        src: 'src/<%= pkg.name %>.js',
        dest: 'build/<%= pkg.name %>.min.js'
      }
    },
    /*concat: {
      options: {
        separator: ';'
      },
    },*/
    bower_concat: {
      all: {
        dest: 'site/static/js/lib/common.js',
        cssDest: 'site/static/css/lib/common.css',
        dependencies: {
          'bootstrap-table': 'bootstrap'
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-bower-concat');

  // Default task(s).
  grunt.registerTask('default', ['bower_concat']);

};
