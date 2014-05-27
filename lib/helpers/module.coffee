# grunt-tusks
# http://kellybecker.me
#
# Copyright (c) 2014 Kelly Becker
# Licensed under the MIT license.
'use strict'

# Coffee Script - Module: Source From (No Credit Taken)
# Source: http://arcturo.github.io/library/coffeescript/03_classes.html

moduleKeywords = ['extended', 'included']

module.exports = class Module
  @extend: (obj) ->
    for key, value of obj when key not in moduleKeywords
      @[key] = value

    obj.extended?.apply(@)
    this

  @include: (obj) ->
    for key, value of obj when key not in moduleKeywords
      # Assign properties to the prototype
      @::[key] = value

    obj.included?.apply(@)
    this
