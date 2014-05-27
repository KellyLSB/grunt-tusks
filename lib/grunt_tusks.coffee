# grunt-tusks
# http://kellybecker.me
#
# Copyright (c) 2014 Kelly Becker
# Licensed under the MIT license.
'use strict'

# Included Lib.
CSHelp = require('coffee-script/helpers')
Module = require('./helpers/module')
File   = require('./helpers/file')
Chalk  = require('chalk')

# Prototype Hacks
String.prototype.repeat = (times) ->
  CSHelp.repeat(@, times)

module.exports = T = class GruntTusks extends Module
  @init: (@grunt, @projectRoot, @projectBase) ->
    @projectRoot ||= process.cwd()
    @projectBase ||= Path.basename(@projectRoot)


  # Included Libraries
  @CoffeeScriptHelpers: CSHelp
  @Module: Module
  @File:   File
  @Chalk:  Chalk


  constructor: (@task, @options) ->
    @_ = @constructor


  forFiles: (type, cb) ->
    $ = @

    # Each of File Type
    @forEachOfType type, (f) ->
      output = []

      # Destination File Information
      dest =
        type: File.type(f.dest)
        name: File.fullname($.options.buildDir, f.dest)
        path: File.resolve(f.dest, $.options.buildDir)

      # Destination File Path relative to the project root
      dest.relative =
        File.relative($._.projectRoot, dest.path)

      # Destination File Directory
      dest.dir = File.dirname(dest.path)

      # Remove any sources that do not exist and loop.
      f.src.filter($.filterFileNotExist())
           .filter($.filterFileByType(type))
           .forEach (filepath) =>

        # Emtpy Line
        $._.grunt.log.writeln('')

        # Source File Information
        file =
          type: File.type(filepath)
          name: File.fullname(filepath)
          path: File.resolve(filepath)

        # Source File Data
        if $.options.gruntReadSourceFiles || false
          file.data = $._.grunt.file.read(filepath)

        # Source File Path relative to the project root
        file.relative =
          File.relative($._.projectRoot, file.path)

        # Source File Directory
        file.dir = File.dirname(file.path)

        # Process file and push output
        try
          output.push(cb.call(f.orig, file, dest))
        catch e
          $._.grunt.log.warn("Failed to process \"#{filepath}\".")
          $._.grunt.log.error(e)

      # Filter output by removing non string values
      output = output.filter((data) -> typeof data is 'string')

      if output.length < 1
        # No resulting outputted data to save...
        $._.grunt.log.warn "Destination \"#{Chalk.cyan(dest.relative)}\" not " \
          + "written: Processed files returned empty results."
      else
        # Join and normalize the output
        $.options.seperator ||= $._.grunt.util.linefeed.repeat(2)
        output = output.join($.options.seperator)
        output = $._.grunt.util.normalizelf(output)

        # Write the output to a file
        $._.grunt.file.write(dest.relative, output)
        $._.grunt.log.writeln "File \"#{Chalk.cyan(dest.relative)}\" created."

    # Emtpy Line
    @_.grunt.log.writeln('')

  # Filter out files not matching type
  forEachOfType: (type, cb) ->
    $ = @

    method = ->
      files = @files.filter (f1) ->
        f1.src.filter($.filterFileNotExist())
              .filter($.filterFileByType(type))
              .length > 0

      files.forEach(cb)

    #method.$ = @

    method.call(@task)


  # Filter out non existent files
  filterFileNotExist: ->
    $ = @

    (filepath) ->
      if ! $._.grunt.file.exists(filepath)
        $._.grunt.log.warn("Source file \"#{filepath}\" not found.")
        return false
      else true


  filterFileByType: (type) ->
    $ = @

    (filepath) ->
      if ! (File.type(filepath) is type)
        $._.grunt.log.warn "Source file \"#{filepath}\" " \
          + "not a \"#{type}\" file... Skipping for later"
        return false
      else true
