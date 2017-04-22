{graphics: g} = love

class GameSpace
  scroll_speed: 2

  new: (@viewport) =>
    -- center is this box's center
    @aim_box = Box 0, 0, @viewport.w * 0.75, @viewport.h * 0.75
    @aim_box\move_center 0, 0

    @rot = 0
    @ytilt = 0
    @xtilt = 0

    -- the distance traveled
    @offset = 0

  update: (dt) =>
    @offset += dt * @scroll_speed

  scale_factor: (z) =>
    -- z of 0 is screen depth
    b = 1
    math.min 20, b / (z + b)

  draw_at_z: (z, fn) =>
    if z <= -1
      return

    vw = @viewport.w / 2
    vh = @viewport.h / 2

    g.push!
    scale = @scale_factor z

    g.translate -@xtilt * 60, 0

    g.translate vw, vh

    g.rotate @rot

    yadjust = vh - vh * scale
    xadjust = vw - vw * scale

    g.translate xadjust * @xtilt, yadjust * @ytilt

    g.translate(
      z * 1 * math.cos(3 + @offset * 1.2)
      z * 2 * math.sin @offset
    )

    g.scale scale, scale

    cscale = math.min 1, scale

    COLOR\push 255 * cscale, 255 * cscale, 255 * cscale
    fn!
    COLOR\pop!
    g.pop!

  draw_outline: =>
    t = @offset - math.floor @offset

    pt = pop_in(t, 2.0) / 4
    @draw_at_z pt, ->
      COLOR\pusha (1 - t) * 255
      @aim_box\outline!
      COLOR\pop!

    @draw_at_z 0, ->
      @aim_box\outline!

{ :GameSpace }
