define [
  'jquery',
  'underscore',
  'backbone',
  'raphael',
  'globals',
  'cs!utils',
  'cs!models/whiteboard_tool'
], ($, _, Backbone, Raphael, globals, Utils, WhiteboardToolModel) ->

  # A triangle in the whiteboard
  class WhiteboardTriangleModel extends WhiteboardToolModel

    initialize: (@paper) ->
      super @paper

      # the defintion of this shape, kept so we can redraw the shape whenever needed
      # format: x1, y1, x2, y2, stroke color, thickness
      @definition = [0, 0, 0, 0, "#000", "0px"]

    # Make a triangle on the whiteboard
    # @param  {[type]} x         the x value of the top left corner
    # @param  {[type]} y         the y value of the top left corner
    # @param  {string} colour    the colour of the object
    # @param  {number} thickness the thickness of the object's line(s)
    make: (x, y, colour, thickness) ->
      path = @_buildPath(x, y, x, y, x, y)
      @obj = @paper.path(path)
      @obj.attr Utils.strokeAndThickness(colour, thickness)
      @obj.attr({"stroke-linejoin": "round"})

      @definition =
        shape: "triangle"
        data: [x, y, x, y, @obj.attrs["stroke"], @obj.attrs["stroke-width"]]

      @obj

    # Update triangle drawn
    # @param  {number} x1 the x value of the top left corner
    # @param  {number} y1 the y value of the top left corner
    # @param  {number} x2 the x value of the bottom right corner
    # @param  {number} y2 the y value of the bottom right corner
    update: (x1, y1, x2, y2) ->
      if @obj?
        [xTop, yTop, xBottomLeft, yBottomLeft, xBottomRight, yBottomRight] = @_getCornersFromPoints(x1, y1, x2, y2)

        path = @_buildPath(xTop * @gw + @xOffset, yTop * @gh + @yOffset,
                           xBottomLeft * @gw + @xOffset, yBottomLeft * @gh + @yOffset,
                           xBottomRight * @gw + @xOffset, yBottomRight * @gh + @yOffset)
        @obj.attr path: path

        @definition.data[0] = x1
        @definition.data[1] = y1
        @definition.data[2] = x2
        @definition.data[3] = y2

    # Draw a triangle on the whiteboard
    # @param  {number} x1 the x value of the top left corner
    # @param  {number} y1 the y value of the top left corner
    # @param  {number} x2 the x value of the bottom right corner
    # @param  {number} y2 the y value of the bottom right corner
    # @param  {string} colour    the colour of the object
    # @param  {number} thickness the thickness of the object's line(s)
    draw: (x1, y1, x2, y2, colour, thickness) ->
      [xTop, yTop, xBottomLeft, yBottomLeft, xBottomRight, yBottomRight] = @_getCornersFromPoints(x1, y1, x2, y2)
      path = @_buildPath(xTop, yTop, xBottomLeft, yBottomLeft, xBottomRight, yBottomRight)
      path = @_scaleTrianglePath(path, @gw, @gh, @xOffset, @yOffset)
      triangle = @paper.path(path)
      triangle.attr Utils.strokeAndThickness(colour, thickness)
      triangle.attr({"stroke-linejoin": "round"})
      triangle

    _getCornersFromPoints: (x1, y1, x2, y2) ->
      xTop = (((x2 - x1) / 2) + x1)
      yTop = y1
      xBottomLeft = x1
      yBottomLeft = y2
      xBottomRight = x2
      yBottomRight = y2
      [xTop, yTop, xBottomLeft, yBottomLeft, xBottomRight, yBottomRight]

    _buildPath: (xTop, yTop, xBottomLeft, yBottomLeft, xBottomRight, yBottomRight) ->
      "M#{xTop},#{yTop},#{xBottomLeft},#{yBottomLeft},#{xBottomRight},#{yBottomRight}z"

    # Scales a triangle path string to fit within a width and height of the new paper size
    # @param  {number} w width of the shape as a percentage of the original width
    # @param  {number} h height of the shape as a percentage of the original height
    # @return {string}   the path string after being manipulated to new paper size
    _scaleTrianglePath: (string, w, h, xOffset=0, yOffset=0) ->
      path = null
      points = string.match(/(\d+[.]?\d*)/g)
      len = points.length
      j = 0

      # go through each point and multiply it by the new height and width
      path = "M"
      while j < len
        path += "," unless j is 0
        path += "" + (points[j] * w + xOffset) + "," + (points[j + 1] * h + yOffset)
        j += 2
      path + "z"

  WhiteboardTriangleModel
