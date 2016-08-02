class pullRefresh
  defaultOptions:
    pocketHeight: 30
    duration: 1000
    fail: (res)->
      console.error res
    always: (res)->
      @resetPullRefresh(@options.duration)

  constructor: (@element, @options)->
    @options = $.extend({}, @defaultOptions, @options)
    @createPullRefresh()
    @enablePullRefresh()

  isScrollBottom: ()->
    a = if document.documentElement.scrollTop then document.documentElement.clientHeight else document.body.clientHeight
    b = if document.documentElement.scrollTop then document.documentElement.scrollTop else document.body.scrollTop
    c = if document.documentElement.scrollTop then document.documentElement.scrollHeight else document.body.scrollHeight
    return (c- a - b <= 5)

  isPullUp: ()->
    return !!(@touchstart.clientY - @touchend.clientY > 100)

  createPullRefresh: ()->
    @pullRefresh = $('<div class="pullRefresh"></div>')[0]
    $(@pullRefresh).append @pullRefreshScroll = $('<div class="pullRefreshScroll"></div>')[0]
    $(@pullRefresh).append @pullRefreshPocket = $('<div class="pullRefreshPocket">上拉加载</div>')[0]
    $(@pullRefreshScroll).append $(@element).clone()
    $(@element).replaceWith $(@pullRefresh)
    @element = @pullRefreshScroll.children[0]

  enablePullRefresh: ()->
    @pullRefreshScroll.style.webkitTransition = "-webkit-transform 0.3s ease-in"
    @pullRefreshScroll.style.webkitTransform = null
    @pullRefreshPocket.style.webkitTransition = "-webkit-transform 0.3s ease-in"
    @pullRefreshPocket.style.webkitTransform = null
    @pullRefreshPocket.style.display = "none"
    _this = @
    @touchHandles = {
      touchstart: (touchEvent)->
        _this.touchstart = $.extend({}, touchEvent.touches[0])
        _this.readyPullRefresh(touchEvent) if _this.isScrollBottom()
      touchend: (touchEvent)->
        _this.touchend = $.extend({},touchEvent.changedTouches[0])
        if _this.isPullUp()
          _this.startPullRefresh()
        else
          _this.resetPullRefresh()
    }
    @pullRefreshScroll.addEventListener "touchstart", @touchHandles.touchstart
    @pullRefreshScroll.addEventListener "touchend", @touchHandles.touchend
    @pullRefreshEnable = true

  disablePullRefresh: ()->
    return unless @pullRefreshEnable
    _this = @
    @resetPullRefresh @options.duration, ->
      _this.pullRefreshEnable = false
      _this.pullRefreshScroll.style.webkitTransform = null
      _this.pullRefreshPocket.style.webkitTransform = null
      _this.pullRefreshScroll.removeEventListener "touchstart", _this.touchHandles.touchstart
      _this.pullRefreshScroll.removeEventListener "touchend", _this.touchHandles.touchend

  readyPullRefresh: (touchEvent)->
    return if @pullRefreshReady
    @pullRefresh.style.height = "#{@pullRefreshScroll.offsetHeight}px"
    @pullRefresh.style.minHeight = "#{window.screen.availHeight - @pullRefresh.offsetTop}px"
    @pullRefresh.style.overflow = "hidden"
    @pullRefreshScroll.style.webkitTransform = null
    @pullRefreshPocket.style.webkitTransform = null
    @pullRefreshPocket.style.display = "block"
    @options.pocketHeight = @pullRefreshPocket.offsetHeight
    @pullRefreshReady = true

  resetPullRefresh: (duration, callback)->
    _this = @
    self = ->
      _this.pullRefreshPocket.style.webkitTransform = null
      _this.pullRefreshPocket.style.display = "none"
      _this.pullRefreshPocket.innerText = "上拉加载"
      _this.pullRefreshScroll.style.webkitTransform = null
      _this.pullRefresh.style.height = "auto"
      _this.pullRefresh.style.overflow = "auto"
      _this.touchstart = null
      _this.touchend = null
      _this.pullRefreshReady = false
      _this.pullRefreshStart = false
      callback.call(_this) if $.isFunction(callback)
    setTimeout self, duration || 0

  startPullRefresh: ()->
    return if !@pullRefreshReady or @pullRefreshStart
    @pullRefreshStart = true
    @pullRefreshPocket.innerText = "正在加载中..."
    @pullRefreshScroll.style.webkitTransform = "translate3d(0,-#{@options.pocketHeight}px,0)"
    @pullRefreshPocket.style.webkitTransform = "translate3d(0,-#{@options.pocketHeight}px,0)"
    _this = @
    $.ajax($.extend({type:"POST", dataType:"json", data:@options.data||{}, url: @options.url}, @options.ajax))
      .done (res)->
        _this.options.done.call(_this, res) if $.isFunction(_this.options.done)
      .fail (res)->
        _this.pullRefreshPocket.innerText = "#{res.status} (#{res.statusText})"
        _this.options.fail.call(_this, res) if $.isFunction(_this.options.fail)
      .always (res)->
        _this.options.always.call(_this, res) if $.isFunction(_this.options.always)
    false

$.fn.pullRefresh = (options)->
  new pullRefresh(this, options)