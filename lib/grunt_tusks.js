'use strict';
var CSHelp, Chalk, File, GruntTusks, Module, T,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CSHelp = require('coffee-script/helpers');

Module = require('./helpers/module');

File = require('./helpers/file');

Chalk = require('chalk');

String.prototype.repeat = function(times) {
  return CSHelp.repeat(this, times);
};

module.exports = T = GruntTusks = (function(_super) {
  __extends(GruntTusks, _super);

  GruntTusks.init = function(grunt, projectRoot, projectBase) {
    this.grunt = grunt;
    this.projectRoot = projectRoot;
    this.projectBase = projectBase;
    this.projectRoot || (this.projectRoot = process.cwd());
    return this.projectBase || (this.projectBase = Path.basename(this.projectRoot));
  };

  GruntTusks.CoffeeScriptHelpers = CSHelp;

  GruntTusks.Module = Module;

  GruntTusks.File = File;

  GruntTusks.Chalk = Chalk;

  function GruntTusks(task, options) {
    this.task = task;
    this.options = options;
    this._ = this.constructor;
  }

  GruntTusks.prototype.forFiles = function(type, cb) {
    var $;
    $ = this;
    this.forEachOfType(type, function(f) {
      var dest, output, _base;
      output = [];
      dest = {
        type: File.type(f.dest),
        name: File.fullname($.options.buildDir, f.dest),
        path: File.resolve(f.dest, $.options.buildDir)
      };
      dest.relative = File.relative($._.projectRoot, dest.path);
      dest.dir = File.dirname(dest.path);
      f.src.filter($.filterFileNotExist()).filter($.filterFileByType(type)).forEach((function(_this) {
        return function(filepath) {
          var e, file;
          $._.grunt.log.writeln('');
          file = {
            type: File.type(filepath),
            name: File.fullname(filepath),
            path: File.resolve(filepath)
          };
          if ($.options.gruntReadSourceFiles || false) {
            file.data = $._.grunt.file.read(filepath);
          }
          file.relative = File.relative($._.projectRoot, file.path);
          file.dir = File.dirname(file.path);
          try {
            return output.push(cb.call(f.orig, file, dest));
          } catch (_error) {
            e = _error;
            $._.grunt.log.warn("Failed to process \"" + filepath + "\".");
            return $._.grunt.log.error(e);
          }
        };
      })(this));
      output = output.filter(function(data) {
        return typeof data === 'string';
      });
      if (output.length < 1) {
        return $._.grunt.log.warn(("Destination \"" + (Chalk.cyan(dest.relative)) + "\" not ") + "written: Processed files returned empty results.");
      } else {
        (_base = $.options).seperator || (_base.seperator = $._.grunt.util.linefeed.repeat(2));
        output = output.join($.options.seperator);
        output = $._.grunt.util.normalizelf(output);
        $._.grunt.file.write(dest.relative, output);
        return $._.grunt.log.writeln("File \"" + (Chalk.cyan(dest.relative)) + "\" created.");
      }
    });
    return this._.grunt.log.writeln('');
  };

  GruntTusks.prototype.forEachOfType = function(type, cb) {
    var $, method;
    $ = this;
    method = function() {
      var files;
      files = this.files.filter(function(f1) {
        return f1.src.filter($.filterFileNotExist()).filter($.filterFileByType(type)).length > 0;
      });
      return files.forEach(cb);
    };
    return method.call(this.task);
  };

  GruntTusks.prototype.filterFileNotExist = function() {
    var $;
    $ = this;
    return function(filepath) {
      if (!$._.grunt.file.exists(filepath)) {
        $._.grunt.log.warn("Source file \"" + filepath + "\" not found.");
        return false;
      } else {
        return true;
      }
    };
  };

  GruntTusks.prototype.filterFileByType = function(type) {
    var $;
    $ = this;
    return function(filepath) {
      if (!(File.type(filepath) === type)) {
        $._.grunt.log.warn(("Source file \"" + filepath + "\" ") + ("not a \"" + type + "\" file... Skipping for later"));
        return false;
      } else {
        return true;
      }
    };
  };

  return GruntTusks;

})(Module);
