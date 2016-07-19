class mask
  defaultOptions: {
    _onShowMask: ->
      false
    _onHideMask: ->
      false
    _onClickMask: ->
      false
    do: (funName, content)->
      @[funName](content) if $.isFunction(@[funName])
    container: "body"
    zIndex: 999
    opacity: 0.5
    backgroundColor: "#000"
  }
  constructor: (@options)->
    @options = $.extend(@defaultOptions, @options)

  createMask: ->
    str =  '<div class="mask" style="display:none;position:fixed;top:0;left:0;right:0;bottom:0;'
    str += "z-index:#{@options.zIndex};background-color:#{@options.backgroundColor};opacity:#{@options.opacity}"
    str += '"></div>'
    $mask = $(str)
    $mask.data("mask", @)
    @maskElement = $mask[0]
    $(@options.container).append(@maskElement)
    return @
  show: (callback)->
    $(@maskElement).show()
    $(@options.container).css("overflow","hidden")
    event = new Event("custom-mask")
    event.srcElement = event.target = @maskElement
    @options.do("_onShowMask", event)
    callback.call(@, event) if $.isFunction(callback)
    return @
  hide: (callback)->
    $(@maskElement).hide()
    $(@options.container).css("overflow","")
    event = new Event("custom-mask")
    event.srcElement = event.target = @maskElement
    @options.do("_onHideMask", event)
    callback.call(@, event) if $.isFunction(callback)
    return @


$.createMask = $.fn.createMask = (options)->
  options.container = this if this instanceof jQuery
  return new mask(options).createMask()

module.exports = $.createMask