# grunt-tusks
# http://kellybecker.me
#
# Copyright (c) 2014 Kelly Becker
# Licensed under the MIT license.
'use strict'


# Included Lib.
Module = require('./helpers/module')

# Grunt Tusks
module.exports = TP = class TuskPlugin extends Module
  @init: (@gruntTusk) ->
    @T = @gruntTusk


  @loadLocal: (name, init, args...) ->
