window.myValidate = class validate
  constructor: (@form)->
    @formElement = @form[0]
    @validFlag = false
    @validated = false
    @handles = {}
    @handleMessages = {}
    @fields = {}
    @options = {
      addValidateListener: true
      errorClass:"error"
      errorMessageClass:"error-message"
    }
    @fn = validate.prototype
  @fn: validate.prototype
  @addRule: (ruleName, message, rule)->
    if $.isFunction(rule)
      validate.prototype.rules[ruleName] = rule
      validate.prototype.ruleMessages[ruleName] = message
  rules: {}
  ruleMessages: {}
  
  addRule: @addRule

  addHandle: (fieldName, ruleName, parameter)->
    handle = {fieldName:fieldName, ruleName:ruleName, parameter:parameter}
    handle.fieldSet = @formElement[fieldName]
    if handle.fieldSet and handle.fieldSet.length and !handle.fieldSet.type
      handle.field = handle.fieldSet[0]
    else
      handle.field = handle.fieldSet
    if handle.field
      handle.field.myValidateListener or (handle.field.myValidateListener = {})
      handle.field.myValidateHandles or (handle.field.myValidateHandles = [])
      handle.field.myValidateHandles.push(handle)
      @fields["#{fieldName}"] = handle.field
      @handles["#{fieldName}-#{ruleName}"] = handle
    return handle

  getHandle: (handleName)->
    return @handles["#{handleName}"] || {}

  addMessage: (fieldName, ruleName, message)->
    @handleMessages["#{fieldName}-#{ruleName}"] = message

  callRule: (field, handle)->
    return unless field and field.disabled isnt on
    rule = @fn.rules[handle.ruleName]
    message = @fn.ruleMessages[handle.ruleName]
    unless rule
      message = "No such rule [#{handle.ruleName}]!"
    else
      message = if handle.message then handle.message else @fn.ruleMessages[handle.ruleName]
    message = "" if success = rule? and rule.call(field, handle.parameter)
    message = message.replace(/\$0/g, handle.ruleName).replace(/\$1/g, handle.fieldName).replace(/\$2/g, "#{field.value}").replace(/\$3/g, "#{handle.parameter}")
    handle.result = {success: success, message: message}
    field.myValidateResults = field.myValidateResults || {}
    field.myValidateResults["#{handle.fieldName}-#{handle.ruleName}"] = handle.result
    return success

  getMultipleFields: (field)->
    return @formElement[field.name]

  addErrorClass: (field)->
    if field.type is "checkbox" or field.type is "radio"
      $fields = $(@getMultipleFields(field))
      $fields.addClass(@options.errorClass)
    else
      $(field).addClass(@options.errorClass)

  removeErrorClass: (field)->
    if field.type is "checkbox" or field.type is "radio"
      $fields = $(@getMultipleFields(field))
      $fields.removeClass(@options.errorClass)
    else
      $(field).removeClass(@options.errorClass)

  raiseField: (field, callback, mode, handleName)->
    error = ""
    if handleName
      result = field.myValidateResults[handleName]
    else
      for _handleName of field.myValidateResults
        result = field.myValidateResults[_handleName]
        break unless result.success
    if result and !result.success
      $field = $(field)
      $field.attr("data-valid", result.success)
      $field.attr("data-error", result.message)
      error = result.message
      @addErrorClass(field)
      callback.call(field, result, mode) if $.isFunction(callback)
    return error

  raiseForm: (callback, mode)->
    that = @
    formResult = {success:true, message:""}
    for fieldName of @fields
      field =  @fields[fieldName]
      result = {success:true, message:""}
      handles = field.myValidateHandles 
      for index of handles
        handle = handles[index]
        if handle.fieldSet and handle.fieldSet.length and !handle.fieldSet.type and field.type isnt "checkbox" and field.type isnt "radio"
          $.each handle.fieldSet, ->
            error = that.raiseField(this, callback, mode, "#{handle.fieldName}-#{handle.ruleName}")
            if error
              formResult.success = false
              formResult.message += "#{error}<br>"
        else
          error = that.raiseField(handle.field, callback, mode, "#{handle.fieldName}-#{handle.ruleName}")
          if error
            formResult.success = false
            formResult.message += "#{error}<br>"
    @validFlag = formResult.success
    @form.attr("data-valid", formResult.success)
    @form.attr("data-error", formResult.message)
    @validated = true
    callback.call(@form, formResult, mode) if $.isFunction(callback)

  resetField: (field, callback)->
    field.myValidateResults = null
    handles = field.myValidateHandles 
    for index of field.myValidateHandles 
      handle = handles[index]
      handle.result = null;
    $field = $(field)
    $field.removeAttr("data-valid")
    $field.removeAttr("data-error")
    @removeErrorClass(field)
    callback.call(field) if $.isFunction(callback)

  resetForm: (callback)->
    that = @
    for handleName of @handles
      handle = @handles[handleName]
      handle.result = null;
      if handle.fieldSet and handle.fieldSet.length and !handle.fieldSet.type
        $.each handle.fieldSet, ->
          that.resetField(this, callback)
      else
        that.resetField(handle.field, callback)
    @form.removeAttr("data-valid")
    @form.removeAttr("data-error")
    @validated = false
    callback.call(@form) if $.isFunction(callback)

  addlistener: (field, listener)->
    return unless field
    that = @
    selector =  if field.tagName is "INPUT" then "input[type='#{field.type}'][name='#{field.name}']" else "#{field.tagName}[name='#{field.name}']"
    that.form.on "#{listener}", "#{selector}", (e)->
      handles = field.myValidateHandles
      that.resetField(this, that.options.clearError)
      for index of handles
        handle = handles[index]
        break unless that.callRule(this, handle)
      that.raiseField(this, that.options.showError, listener)
      true
    field.myValidateListener[listener] = true

  init: (options)->
    @options = $.extend(true, @options, options)
    if @options.rules
      for fieldName of @options.rules
        for ruleName of @options.rules[fieldName]
          if parameter = @options.rules[fieldName][ruleName]
            @addHandle(fieldName, ruleName, parameter)
    if @options.messages
      for fieldName of @options.messages
        for ruleName of @options.rules[fieldName]
          @getHandle("#{fieldName}-#{ruleName}").message = @options.messages[fieldName][ruleName]

  run: ()->
    that = @
    @resetForm(@options.clearError)
    for fieldName of @fields
      field =  @fields[fieldName]
      if field and @options.addValidateListener and field.myValidateListener
        listener = if (field.type is "checkbox" or field.type is "radio") then "change" else "blur"
        @addlistener(field, listener) unless field.myValidateListener[listener]
      handles = field.myValidateHandles
      for index of handles
        handle = handles[index]
        if handle.fieldSet and handle.fieldSet.length and !handle.fieldSet.type
          breakFlag = false
          $.each handle.fieldSet, ->
            breakFlag = true unless that.callRule(this, handle)
          break if breakFlag
        else
          break unless @callRule(handle.field, handle)
    @raiseForm(@options.showError, "submit")
    return @validFlag

  valid: ()->
    return if @validated then @validFlag else @run()

_getLength = (field)->
  length = 0
  if field.type is "checkbox" or field.type is "radio"
    length = $(field).closest("form").find("[type=#{field.type}][name=#{field.name}]:checked").length
  else if field.value
    length = (field.value+"").length
  return length

#添加默认的规则函数
validate.addRule "required", "字段[$1]必填！", (parameter)->
  return ((this.type isnt "checkbox" and this.type isnt "radio") and this.value isnt null and this.value isnt "") or ((this.type is "checkbox" or this.type is "radio") and !!_getLength(this)) 

validate.addRule "length", "字段[$1]长度必须为$3！", (parameter)->
  len = parseInt(parameter)
  length = _getLength(this)
  return (length == len)

validate.addRule "maxlength", "字段[$1]长度不能超出$3！", (parameter)->
  maxLength = parseInt(parameter)
  length = _getLength(this)
  return (length <= maxLength)

validate.addRule "minlength", "字段[$1]长度不能小于$3！", (parameter)->
  minLength = parseInt(parameter)
  length = _getLength(this)
  return (length >= minLength)

validate.addRule "rangelength", "字段[$1]长度不能溢出区间[$3]！", (parameter)->
  minLength = parseInt(parameter[0])
  maxLength = parseInt(parameter[1])
  length = _getLength(this)
  return (length <= maxLength and length >= minLength)

validate.addRule "phone", "请输入有效的电话号码！", (parameter)->
  pattern = /(^[0-9]{3,4}\-[0-9]{7,8}$)|(^[0-9]{7,8}$)|(^[0-9]{3,4}\-[0-9]{7,8}\-[0-9]{3,5}$)|(^[0-9]{7,8}\-[0-9]{3,5}$)|(^\([0-9]{3,4}\)[0-9]{7,8}$)|(^\([0-9]{3,4}\)[0-9]{7,8}\-[0-9]{3,5}$)|(^1[3,4,5,7,8]{1}[0-9]{9}$)/
  return pattern.test(this.value)

validate.addRule "email", "请输入有效的电子邮箱！", (parameter)->
  pattern = /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  return pattern.test(this.value)

validate.addRule "number", "请输入有效的数字！", (parameter)->
  return !isNaN(this.value)

validate.addRule "max", "请输入小于$3的数字！", (parameter)->
  max = parseFloat(parameter)
  return true unless this.value
  return !isNaN(this.value) and parseFloat(this.value) <= max

validate.addRule "min", "请输入大于$3的数字！", (parameter)->
  min = parseFloat(parameter)
  return true unless this.value
  return !isNaN(this.value) and parseFloat(this.value) >= min

validate.addRule "equal", "请输入和$3相同的值！", (parameter)->
  $toField = $("[name='#{parameter}']")
  if $toField.length>0
    return ("#{this.value}" is "#{$toField.val()}")
  else
    return ("#{this.value}" is "#{parameter}")

validate.addRule "date", "请输入有效的日期！", (parameter)->
  return !/Invalid|NaN/.test(new Date(this.value).toString())

#扩展jquery
$.fn.validate = (options)->
  validator = this.data("validator")
  unless validator
    this.data("validator", validator = new validate(this))
    validator.init(options)
  return validator