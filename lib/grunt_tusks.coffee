# grunt-tusks
# http://kellybecker.me
#
# Copyright (c) 2014 Kelly Becker
# Licensed under the MIT license.
'use strict'

# CoffeeScript Helpers
CoffeeHelpers = require('coffee-script').helpers

# Prototype Hacks
String.prototype.repeat = (times) ->
  CoffeeHelpers.repeat(@, times)

Array.prototype.diff = (compare) ->
  @filter (i) -> compare.indexOf(i) < 0

Array.prototype.thisFilter = (thisArg, cb) ->
  @filter(cb, thisArg)

# Grunt Tusks
module.exports = T = class GruntTusks

  # Tusks
  @Plugins: {}

  # Included Libraries.
  @Library:
    CoffeeHelpers:   CoffeeHelpers
    Merge:           CoffeeHelpers.merge
    Extend:          (o, ps...) ->
      CoffeeHelpers.extend(o, p) for p in ps; o
    Module:          require('./helpers/module')
    File:            require('./helpers/file')
    Chalk:           require('chalk')

  # Configuration
  @Config:
    projectRoot:     null
    projectBase:     null
    grunt:           null


  @Initialized: false

  # Custom Extend
  @Mix: (into, args...) ->
    @Extend into, @Library, @Plugins, {
      Config: @Config,
      grunt: @grunt
    }, args...

  @init: (grunt, projectRoot, projectBase, cb) ->

    # Allow optional arguments
    if ! cb && typeof projectBase is 'function'
      [cb, projectBase] = [projectBase, null]
    else if ! cb && ! projectBase && typeof projectRoot is 'function'
      [cb, projectRoot, projectBase] = [projectRoot, null, null]

    # Populate projectRoot and projectBase
    projectRoot ||= process.cwd()
    projectBase ||= @Library.File.basename(projectRoot)

    # Set the config values
    @Library.Extend @Config,
      projectRoot: projectRoot
      projectBase: projectBase
      grunt: grunt

    # Merge lib and config into object
    @Library.Extend(@, @Library)
    @Library.Extend(@, @Config)

    # Mark as Initialized
    @Initialized = true

    # Allow adding plugins
    try
      if typeof cb is 'function'
        cb.call(@Plugins, @Config)

        for plugin, object of @Plugins
          @Mix object

          if typeof object.onTusksInit is 'function'
            object.onTusksInit(@)
    catch e
      console.error(e)
      # Whoops there was error.
      # Unmark the initialization
      @Initialized = false
      return false

    return @

  constructor: (@task, @options) ->
    (@_ = @constructor).Mix @task,
      options: @options

    ((@$)->).call(@task, @)

  forFiles: (type, cb) ->
    @forEachOfType type, (f) ->
      output = []

      # Destination File Information
      dest =
        type: @File.type(f.dest)
        name: @File.fullname(@options.buildDir, f.dest)
        path: @File.resolve(f.dest, @options.buildDir)

      # Destination File Path relative to the project root
      dest.relative = @File.relative(@Config.projectRoot, dest.path)

      # Destination File Directory
      dest.dir = @File.dirname(dest.path)

      # Remove any sources that do not exist and loop.
      f.src.filter(@$.filterFileNotExist.call(@))
           .filter(@$.filterFileByType.call(@, type))
           .forEach (filepath) =>

        # Emtpy Line
        @grunt.log.writeln('')

        # Source File Information
        file =
          type: @File.type(filepath)
          name: @File.fullname(filepath)
          path: @File.resolve(filepath)

        # Source File Path relative to the project root
        file.relative = @File.relative(@Config.projectRoot, file.path)

        # Source File Directory
        file.dir = @File.dirname(file.path)

        # Source File Data
        if @options.gruntReadSourceFiles || false
          @grunt.log.writeln "Reading source file \"#{file.relative}\"."
          file.data = @grunt.file.read(filepath)

        # Process file and push output
        try
          (data = cb.call(f.orig, file, dest)) && output.push(data)
        catch e
          @grunt.log.warn "Failed to process \"#{@Chalk.cyan(file.relative)}\"."
          @grunt.log.error(e)

      # Filter output by removing non string values
      output = output.filter((data) -> typeof data is 'string')

      if output.length < 1
        # No resulting outputted data to save...
        @grunt.log.warn "Destination \"#{@Chalk.cyan(dest.relative)}\" " \
          + "not written: Processed files returned empty results."
      else
        # Join and normalize the output
        @options.seperator ||= @grunt.util.linefeed.repeat(2)
        output = output.join(@options.seperator || "\n")
        output = @grunt.util.normalizelf(output)

        # Write the output to a file
        @grunt.file.write(dest.relative, output)
        @grunt.log.writeln "File \"#{@Chalk.cyan(dest.relative)}\" created."

      # Emtpy Line
      @grunt.log.writeln('')

  # Filter out files not matching type
  forEachOfType: (type, cb) ->
    method = ->
      files = @files.filter (f1) =>
        f1.src.filter(@$.filterFileNotExist.call(@))
              .filter(@$.filterFileByType.call(@, type))
              .length > 0

      files.forEach (f) =>
        @$._.Mix f.orig,
          options: @options

        ((@$)->).call(@, @$)

        cb.call(@, f)

    method.call(@task)


  # Filter out non existent files
  filterFileNotExist: ->
    (filepath) =>
      if ! @grunt.file.exists(filepath)
        @grunt.log.warn "Source file \"#{filepath}\" not found."
        return false
      else true


  filterFileByType: (type) ->
    (filepath) =>
      if ! (@File.type(filepath) is type)
        @grunt.log.warn "Source file \"#{filepath}\" " \
          + "not a \"#{type}\" file... Skipping for later"
        return false
      else true
