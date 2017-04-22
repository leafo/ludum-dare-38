{graphics: g} = love

approach_vector = (start, stop, dt) ->
  for i=1,2
    start[i] = smooth_approach start[i], stop[i], dt * 5

class Bullet extends Box
  lazy sprite: -> imgfy "images/bullet.png"
  alive: true
  is_bullet: true

  new: (x, y, @z, @speed) =>
    super 0, 0, @sprite\width!, @sprite\height!
    @move_center x, y

  update: (dt) =>
    @z += dt * @speed
    @z < 3

  draw: (world) =>
    world.space\draw_at_z @z, ->
      @sprite\draw @x, @y

class Player
  aim_depth: 10
  aim_speed: 200
  scale_cursor: 1

  lazy cursor: -> imgfy "images/cursor.png"
  lazy cursor_center: -> imgfy "images/cursor_center.png"

  lazy player_sprite: ->
    Spriter "images/player.png", 32, 16

  new: =>
    @aim_pos = Vec2d!
    @player_pos = Vec2d!
    @player_vel = Vec2d!
    @player_z = -0.1
    @hud_z = 0.2

  move_aim: (space, dx, dy) =>
    @aim_pos\move dx, dy
    @aim_pos = space.aim_box\clamp_vector @aim_pos

  get_rotation: =>
    unless @player_vel
      return 0

    max_rot = 120

    p = math.max(math.min(@player_vel[1], max_rot), -max_rot) / max_rot
    sign = p == 0 and 1 or p / math.abs(p)
    p = sign * math.abs(p)^2
    p * math.pi / 24

  shoot: (world) =>
    AUDIO\play "shoot"
    bx, by = unpack @player_pos
    world.entities\add Bullet bx, by, @player_z, 2
    @scale_cursor = 1 + random_normal!

  update: (dt, world) =>
    vec = CONTROLLER\movement_vector dt
    vec *= @aim_speed

    @move_aim world.space, unpack vec

    px, py = unpack @player_pos

    approach_vector @player_pos, @aim_pos, dt

    @player_vel = Vec2d(
      (@player_pos[1] - px) / dt
      (@player_pos[2] - py) / dt
    )

    if @scale_cursor > 1
      @scale_cursor = smooth_approach @scale_cursor, 1, dt * 2

    world.space.rot = @get_rotation!
    world.space.ytilt = -(@player_pos[2] / world.viewport.h) * 2
    world.space.xtilt = -(@player_pos[1] / world.viewport.w)

  draw_hud: (world) =>
    space = world.space
    offset = space.offset

    t = offset - math.floor offset

    pt = pop_in(t, 2.0) / 4
    space\draw_at_z pt, ->
      COLOR\pusha (1 - t) * 255
      space.aim_box\outline!
      COLOR\pop!

    cp = @player_pos -
      Vec2d(@cursor_center\width!, @cursor_center\height!) / 2

    space\draw_at_z 0, ->
      space.aim_box\outline!

      @cursor_center\draw unpack cp
      g.push!
      g.translate unpack @aim_pos
      g.scale @scale_cursor, @scale_cursor
      @cursor\draw -@cursor\width!/2, -@cursor\height!/2
      g.pop!


  draw: (world) =>
    -- the under hud
    g.setPointSize 1
    for z=0.2,3,0.2
      world.space\draw_at_z z, ->
        g.points unpack @player_pos

    for frame=2,0,-1
      world.space\draw_at_z frame * 0.05 + @player_z, ->
        g.push!
        g.translate unpack @player_pos
        g.rotate @get_rotation! * 2
        @player_sprite\draw frame, -16, -8
        g.pop!

    @draw_hud world

{:Player, :Bullet}
