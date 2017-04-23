{graphics: g} = love

class GameSpace
  scroll_speed: 2

  new: (@viewport) =>
    -- center is this box's center
    @aim_box = Box 0, 0, @viewport.w * 0.75, @viewport.h * 0.75
    @aim_box\move_center 0, 0

    @rot = 0
    @world_rot = 0
    @ytilt = 0
    @xtilt = 0

    @tunnel_dir_x = 0
    @tunnel_dir_y = 0

    -- the distance traveled
    @offset = 0

  update: (dt) =>
    -- @world_rot += dt
    @offset += dt * @scroll_speed

  scale_factor: (z) =>
    -- z of 0 is screen depth
    b = 1
    math.min 20, b / (z + b)

  -- project a single point, this should be synchronized with drawz
  project: (x, y, z) =>
    scale = @scale_factor z

    vw = @viewport.w / 2
    vh = @viewport.h / 2

    yadjust = vh - vh * scale
    xadjust = vw - vw * scale

    bend = Vec2d @tunnel_bend z

    adjust = Vec2d(
      xadjust * @xtilt
      yadjust * (@ytilt - 0.5)
    )

    tilt = Vec2d(
      -@xtilt * 60
      0
    )

    unpack (Vec2d(x,y) * scale + bend + adjust)\rotate(@rot + @world_rot) + Vec2d(vw, vh) + tilt

  -- unproject screen rotation for input
  unproject_rot: (x,y) =>
    unpack Vec2d(x,y)\rotate -(@rot + @world_rot)

  tunnel_bend: (z) =>
    z * (1 * math.cos(3 + @offset * 1.2) + @tunnel_dir_x), z * (2 * math.sin(@offset) + @tunnel_dir_y)

  draw_at_z: (z, fn) =>
    if z <= -1
      return

    vw = @viewport.w / 2
    vh = @viewport.h / 2

    scale = @scale_factor z
    yadjust = vh - vh * scale
    xadjust = vw - vw * scale


    g.push!
    g.translate -@xtilt * 60, 0
    g.translate vw, vh
    g.rotate @rot + @world_rot
    g.translate xadjust * @xtilt, yadjust * (@ytilt - 0.5)
    g.translate @tunnel_bend z
    g.scale scale, scale

    cscale = math.min 1, scale

    COLOR\push 255 * cscale, 255 * cscale, 255 * cscale
    fn!
    COLOR\pop!
    g.pop!

{ :GameSpace }
