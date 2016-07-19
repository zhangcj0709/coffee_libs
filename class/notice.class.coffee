class myNotice
  constructor: (@target, @options) ->
    @options = @options || {}
    #@direction = if ["left","right","top", "bottom"].indexOf(@options.direction)>-1 then @options.direction else "top"
    @direction = "top"
    @duration = if (rate = parseInt(@options.duration)) then rate else 1000; #过渡效果持续时间
    @rate = if (rate = parseInt(@options.rate)) then rate else 5000; #切换频率
    @loop = !!@options.loop
    @actived = null
    @list = @target.children("li")
    @length = @list.length
    @prePosition = @position()
  position: ()->
    return @target.position()[@direction]
  reset: (callback)->
    callback = (->false) unless $.isFunction(callback)
    css = {}
    css[@direction] = @prePosition
    @target.css(css)
    @target.children(".tran").remove()
    return @
  changeTo: (index)->
    that = @
    index = parseInt(index) || 0
    css = {}
    if index is 0
      css[@direction] = "-#{@length}00%"
      $first = $(@list.first())
      @target.append("<li class='tran'>#{$first.html()}</li>").animate css, @duration, ->
        that.reset()
    else
      css[@direction] = "-#{index}00%"
      @target.animate(css, @duration)
    @actived = index;
    return @
  start: ()->
    that = @
    next = (that.actived || 0) + 1
    doing = (callback)->
      next = 0 if next >= that.length
      that.changeTo next
      next++
    that.stop(true)
    that.startHandle = setInterval doing, that.rate
    that.target
      .on "mouseover", ->
        that.stop()
      .on "mouseout", ->
        that.start()
    that.loop = true
    return that
  stop: (offEnvent)->
    clearInterval(@startHandle) if @startHandle
    if offEnvent
      @target.off("mouseover").off("mouseout")
    @loop = false
    return @
  init: ()->
    @start() if @loop is on
    @target.data("notice", @)
    return @

$.fn.myNotice = (options)->
  new myNotice(this, options).init()