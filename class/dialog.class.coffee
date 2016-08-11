# css: app/styles/base/_popup.scss
# demo: app/views/sample/dialog

class myDialog
  @CLASS_POPUP: "popup"
  @CLASS_POPUP_IN: "popup-in"
  @CLASS_POPUP_OUT: "popup-out"
  @CLASS_POPUP_INNER: "popup-inner"
  @CLASS_POPUP_TITLE: "popup-title"
  @CLASS_POPUP_TEXT: "popup-text"
  @CLASS_POPUP_BUTTONS: "popup-buttons"
  @CLASS_POPUP_BUTTON: "popup-button"
  @CLASS_POPUP_INPUT: "popup-input"

  @popupStack = []
  @backdrop = require("class/mask.class")({zIndex:9999})
  @createInput = (placeholder, type, value)->
    return '<div class="' + @CLASS_POPUP_INPUT + '"><input type="'+ (type || 'text') + '" autofocus placeholder="' + (placeholder || '') + '" value="' + (value || '') + '"/></div>'
  @createInner = (message, title, extra)->
    res = '<div class="' + @CLASS_POPUP_INNER + '">'
    res += '<div class="' + @CLASS_POPUP_TITLE + '">' + (title || '') + '</div>' if title
    res += '<div class="' + @CLASS_POPUP_TEXT + '">' + message + '</div>'
    res += (extra || '') + '</div>'
    return res
  @createButtons = (btnArray)->
    return "" unless btnArray and btnArray.length > 0
    length = btnArray.length
    btns = []
    for btn in btnArray
      btns.push('<span class="' + @CLASS_POPUP_BUTTON  + '">' + btn + '</span>')
    return '<div class="' + @CLASS_POPUP_BUTTONS + '">' + btns.join('') + '</div>'
  @createPopup: (html, callback, extend)->
    that = @
    popupElement = document.createElement('div')
    popupElement.className = @CLASS_POPUP + " #{if extend? and extend.class then extend.class}"
    popupElement.innerHTML = html
    popupElement.style.width = extend.width if extend? and extend.width

    removePopupElement = ()->
      popupElement.parentNode && popupElement.parentNode.removeChild(popupElement);
      popupElement = null;

    popupElement.addEventListener 'webkitTransitionEnd', (e)->
      removePopupElement() if popupElement and e.target is popupElement and popupElement.classList.contains(that.CLASS_POPUP_OUT)

    @backdrop.show()
    popupElement.style.display = 'block'
    document.body.appendChild(popupElement)
    popupElement.offsetHeight
    popupElement.classList.add(@CLASS_POPUP_IN)

    btns = popupElement.querySelectorAll(".#{@CLASS_POPUP_BUTTON}")
    input = popupElement.querySelector(".#{@CLASS_POPUP_INPUT} input")
    popup = {
      element: popupElement,
      close: (index, animate) ->
        if popupElement
          callback && callback((index || 0), (input && input.value || ''))
          if animate is on
            popupElement.classList.remove(that.CLASS_POPUP_IN)
            popupElement.classList.add(that.CLASS_POPUP_OUT)
          else
            removePopupElement()

          that.popupStack.pop()
          #如果还有其他popup，则不remove backdrop
          if that.popupStack.length
            that.popupStack[that.popupStack.length - 1]['show'](animate)
          else
            that.backdrop.hide()
    }
    [].forEach.call btns,  (btn)->
      btn.addEventListener 'click', (e)->
        popup.close([].indexOf.call(btns, e.target), true)

    
    @popupStack[@popupStack.length - 1]['hide']() if @popupStack.length
    @popupStack.push({
      close: popup.close
      show: (animate)->
        if popupElement
          popupElement.style.display = 'block'
          popupElement.offsetHeight
          popupElement.classList.add(that.CLASS_POPUP_IN)
      hide: ()->
        if popupElement
          popupElement.style.display = 'none'
          popupElement.classList.remove(that.CLASS_POPUP_IN)
    })
    return popup

  @createAlert: (message, title, btnValue, callback, extend)->
    title? and (title = title || '提示')
    return @createPopup(@createInner(message, title) + @createButtons(if btnValue is null then [] else [btnValue || '确定']), callback, extend)
  @createConfirm: (message, title, btnArray, callback, extend)->
    title? and (title = title || '提示')
    return @createPopup(@createInner(message, title) + @createButtons(btnArray || ['取消', '确认']), callback, extend)
  @createPrompt: (message, placeholder, title, btnArray, callback, extend)->
    title? and (title = title || '提示')
    return @createPopup(@createInner(message, title, @createInput(placeholder, extend.type, extend.value)) + @createButtons(btnArray || ['取消', '确认']), callback, extend)

module.exports = myDialog