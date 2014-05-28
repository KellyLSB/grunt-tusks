# mashbash
# http://kellybecker.me
#
# Copyright (c) 2014 Kelly Becker
# Licensed under the MIT license.
'use strict'

# Node Lib.
Path = require('path')
Fs   = require('fs')

module.exports = class File

  @resolve: (file, base) ->
    Path.resolve(base || process.cwd(), file)

  @relative: (from, to, base) ->
    if ! base && ! to
      to   = from
      from = process.cwd()

    if ! base
      base = from

    Path.relative(@resolve(from), @resolve(to, base))

  @read: (file, base) ->
    file = @resolve(file, base)
    if Fs.existsSync(file) && \
       Fs.statSync(file).isFile()
      Fs.readFileSync(file, 'utf8')
    else false

  @ext: (file) ->
    @type(file)

  @type: (file) ->
    ext = Path.extname(file)
    ext.substr(1, ext.length)

  @basename: (file) ->
    Path.basename(file)

  @fullname: (from, to, base) ->
    file = @relative(from, to, base)
    file.replace(/\.[\w\d]*$/, '')

  @dirname: (file) ->
    Path.dirname(file)
