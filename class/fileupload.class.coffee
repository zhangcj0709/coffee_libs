_extend = $.extend
_isFunction = $.isFunction

class fileUpload
  constructor: (@file, url, data, options)->
    @options = {
      method: "post"
      url: null
      async: true
      fieldName: "multipartFile"
      maxFileSize: 10
      do: (funName, content)->
        @[funName](content) if _isFunction(@[funName])
      beforeSend: ()->
        false
      complete: ()->
        false
      success: (resp)->
        false
      error: (resp)->
        console.error resp
      checkFileExt: (file)->
        if @fileExts
          fileExt = file.name.substr(file.name.lastIndexOf(".")).toLowerCase()
          if "#{@fileExts}".slice(",").indexOf(fileExt) is -1
            @do("overexts", {responseText:"仅支持上传#{@fileExts}格式的文件！", readyState:4})
            return false
        return true
      checkFileSize: (file)->
        if @maxFileSize
          if file.size > @maxFileSize * 1024 * 1024
            @do("oversize", {responseText:"请上传小于#{@maxFileSize}M的文件！", readyState:4})
            return false
        return true
      overexts: (resp)->
        @do("error", resp)
      oversize: (resp)->
        @do("error", resp)
    }
    @init(file, url, data, options)
    @onreadystatechange = ->
      if (this.readyState == 4)
        if this.status is 200
          resp = this.response
          if "#{this.getResponseHeader('Content-Type')}".indexOf("application/json") is 0
            resp = JSON.parse(resp)
          else
            resp = JSON.parse($(resp).text())
          this.myOptions.do("success", resp)
        else
          this.myOptions.do("error", this)

  init: (file, url, data, options)->
    op = {file:file, url:url, data:data}
    op.success = ((resp)->options.call(resp)) if _isFunction(options)
    @options = _extend(true, @options, op, options)

  getXMLHttp: () ->
    unless @XMLHttp
      if @options.url
        @XMLHttp = new XMLHttpRequest()
        @XMLHttp.myOptions = @options
        @XMLHttp.open(@options.method, @options.url, @options.async); 
        @XMLHttp.setRequestHeader("X-Requested-With", "XMLHttpRequest");
        @XMLHttp.onreadystatechange = @onreadystatechange
      else
        throw("Undefined request url!!")
    return @XMLHttp

  getFormData: ()->
    unless @FormData
      @FormData = new FormData()
      @FormData.append(@options.fieldName, @file)
      if @options.data 
        for name of @options.data
          @FormData.append(name, @options.data[name]) if @options.data[name]
    return @FormData;

  send: ()->
    try
      return unless @options.do("checkFileExt", @file)
      return unless @options.do("checkFileSize", @file)
      @options.do("beforeSend")
      @getXMLHttp().send(@getFormData())
      @options.do("complete")
      @destory()
    catch e
      @options.do("complete")
      @destory()
      @options.do("error", {responseText:e, readyState:4})

  destory: ()->
    @formData = null;
    @XMLHttp = null;


module.exports = (file, url, data, options)->
  new fileUpload(file, url, data, options).send()