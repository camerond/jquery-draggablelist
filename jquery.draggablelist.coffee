# The MIT License (MIT)

# Copyright (c) 2014 Cameron Daigle

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

draggableList =
  name: "draggableList"
  tag_type: "li"
  handle: ".handle"
  dragged_item_id: "draggable_list_item"
  indicator_id: "draggable_list_indicator"
  indicator_padding: 5
  z_index: 10000
  afterDrop: $.noop
  relative_triggers: null
  absolute_triggers: null
  createElements: ->
    @$endcap = @$el.children().eq(-1).clone().empty()
      .insertAfter(@$el.children().eq(-1))
      .css
        "display": "block"
        "opacity": 0
        "border": "none"
        "height": 0
        "padding": 0
        "margin": 0
        "fontSize": 0
        "lineHeight": 0
        "overflow": "hidden"
    @$ghost = $("<div />")
      .html(@$dragging.html())
      .appendTo($("body"))
      .attr("id", @dragged_item_id)
      .css
        position: "absolute"
        width: @$dragging.width()
        height: @$dragging.innerHeight()
        left: @$dragging.offset().left
        top: @$dragging.offset().top
        opacity: 0.7
        zIndex: @z_index + 1
    @$indicator = $("<div />")
      .appendTo($("body"))
      .attr("id", @indicator_id)
      .hide()
      .css
        position: "absolute"
        width: @$ghost.innerWidth() + @indicator_padding * 2
        left: @$ghost.offset().left - @indicator_padding
        zIndex: @z_index
  startDrag: (e) ->
    d = e.data
    d.$handle = $(@)
    d.$dragging = d.$handle.closest(d.tag_type).css
      opacity: 0
    d.createElements()
    $(window)
      .on("mouseup.draggableList", d, d.drop)
      .on("mousemove.draggableList", d, d.move)
    $(document.body).disableSelection()
    false
  drop: (e) ->
    d = e.data
    if !d.$zone or d.$zone.index() is d.$dragging.index()
      d.$dragging.css("opacity", 1)
    else
      d.$dragging.detach().insertBefore(d.$zone).css("opacity", 1)
    d.cleanup()
    d.afterDrop.apply(d.$el)
    false
  move: (e) ->
    d = e.data
    d.$ghost.css
      top: e.pageY - d.$handle.height() / 2
    d.$zone = d.findDropZone(e.pageY) or d.$zone
    if !d.$zone or d.$zone.index() is d.$dragging.index() or d.$zone.index() is d.$dragging.index() + 1
      d.$indicator.hide()
    else
      d.$indicator.show().css
        top: d.$zone.offset().top - d.item_padding
    true
  findDropZone: (y) ->
    $children = @$el.children()
    $first = $children.eq(0)
    $last = $children.eq(-1)
    if y > $last.offset().top - $last.height() * .4
      zone = $last
    else if y < $first.offset().top + $first.height() * .4
      zone = $first
    else
      $children.not($first).not($last).each ->
        $el = $(@)
        top = $el.offset().top
        h = $el.height() * .4
        if y > top - h and y < top + h
          zone = $el
          return false
    zone
  cleanup: ->
      @$ghost.remove()
      @$indicator.remove()
      @$endcap.remove()
      $(document.body).enableSelection()
      $(window).off(".draggableList")
      @$ghost = @$indicator = @$dragging = @$endcap = @$zone = undefined
  bindRelativeTrigger: (t, idx) ->
    d = @
    d.$el.on "click.draggableList", t, ->
      $move = $(@).closest(d.tag_type)
      d.moveElement($move, $move.index() + idx)
  bindAbsoluteTrigger: (t, idx) ->
    d = @
    d.$el.on "click.draggableList", t, ->
      $move = $(@).closest(d.tag_type)
      d.moveElement($move, idx)
  bindInputTrigger: ->
    d = @
    d.$el.on "change.draggableList", d.input_trigger, ->
      d.moveElement($(@).closest(d.tag_type), $(@).val() - 1)
  moveElement: ($move, idx) ->
    $t = $move.parent().children().eq(idx)
    if $move.length and $t.length and idx >= 0
      if $move.index() > idx then $move.insertBefore($t) else $move.insertAfter($t)
    @afterDrop.apply(@$el)
    false
  init: ->
    if @$el.find(@handle).length
      @$el.on("mousedown.draggableList", @handle, @, @startDrag)
      $children = @$el.children()
      @item_padding = ($children.eq(1).offset().top - $children.eq(0).offset().top - $children.eq(0).outerHeight()) / 2
    for t, idx of @relative_triggers
      @bindRelativeTrigger(t, idx)
    for t, idx of @absolute_triggers
      @bindAbsoluteTrigger(t, idx)
    @bindInputTrigger()
$.fn[draggableList.name] = (opts) ->
    $els = @
    method = if $.isPlainObject opts or !opts then "" else opts
    if method && draggableList[method]
      draggableList[method].apply $els, Array.prototype.slice.call arguments, 1
    else if !method
      $els.each (i) ->
        plugin_instance = $.extend true,
          $el: $els.eq(i)
        , draggableList, opts
        $els.eq(i).data draggableList.name, plugin_instance
        plugin_instance.init()
    else
      $.error "Method #{method} does not exist on jQuery.#{draggableList.name}"
    $els

$.fn.disableSelection = ->
  this.attr('unselectable', 'on').addClass("unselectable").each ->
     this.onselectstart = -> false

$.fn.enableSelection = ->
  this.removeAttr('unselectable').removeClass("unselectable").each ->
    this.onselectstart = -> undefined

$.fn.removeAttr = (attr) ->
  this.each ->
    this.removeAttribute(attr)
