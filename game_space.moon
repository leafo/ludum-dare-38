{graphics: g} = love

class GameSpace
  new: (@viewport) =>
    -- center is this box's center
    @aim_box = Box 0, 0, @viewport.w * 0.75, @viewport.h * 0.75
    @aim_box\move_center 0, 0

    @rot = 0
    @tilt = 0

  scale_factor: (z) =>
    -- z of 0 is screen depth
    math.min 20, 1 / (z + 1)

  draw_at_z: (z, fn) =>
    if z <= -1
      return

    g.push!
    scale = @scale_factor z
    g.translate @viewport.w / 2, @viewport.h / 2

    g.rotate @rot

    vh = @viewport.h / 2
    yadjust = vh - vh * scale

    g.translate 0, yadjust * @tilt

    g.scale scale, scale

    cscale = math.min 1, scale

    COLOR\push 255 * cscale, 255 * cscale, 255 * cscale
    fn!
    COLOR\pop!
    g.pop!

  draw_outline: =>
    @draw_at_z 0, ->
      @aim_box\outline!

{ :GameSpace }
