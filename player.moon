{graphics: g} = love

approach_vector = (start, stop, dt) ->
  for i=1,2
    start[i] = smooth_approach start[i], stop[i], dt * 5

class Bullet extends Box
  lazy sprite: -> imgfy "images/bullet.png"
  alive: true
  is_bullet: true
  speed: 2

  new: (x, y, @z) =>
    super 0, 0, @sprite\width!, @sprite\height!
    @move_center x, y

  update: (dt) =>
    @z += dt * @speed
    @z < 3

  draw: (world) =>
    world.space\draw_at_z @z, ->
      @sprite\draw @x, @y

class Missile
  lazy sprite: -> imgfy "images/bullet_green.png"
  alive: true
  is_bullet: true
  speed: 3

  new: (x,y, @z, @target) =>
    super 0, 0, @sprite\width!, @sprite\height!
    @move_center x, y

  draw: (world) =>
    world.space\draw_at_z @z, ->
      @sprite\draw @x, @y

  update: (dt) =>
    @z += dt * @speed
    @z < 3


class Player
  aim_depth: 10
  aim_speed: 200
  scale_cursor: 1
  rot_cursor: 0

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
    world.entities\add Bullet bx, by, @player_z
    @scale_cursor = 1 + random_normal!

  shoot_missile: (world) =>
    print "shoot missile"
    AUDIO\play "missile"
    -- bx, by = unpack @player_pos
    -- world.entities\add Bullet bx, by, @player_z
    enemy = world\get_closest_enemy @player_z
    print "got", enemy

    @rot_cursor = math.pi

  update: (dt, world) =>
    vec = CONTROLLER\movement_vector dt
    vec = Vec2d world.space\unproject_rot unpack vec

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

    if @rot_cursor > 0
      @rot_cursor = smooth_approach @rot_cursor, 0, dt * 6

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

    space\draw_at_z @hud_z, ->
      space.aim_box\outline!
      @cursor_center\draw unpack cp

    -- draw the cursor unprojected so it's easy to see
    cx, cy = space\project @aim_pos[1], @aim_pos[2], @hud_z

    g.push!
    g.translate cx, cy

    if @scale_cursor != 1
      g.scale @scale_cursor, @scale_cursor

    if @rot_cursor > 0
      g.rotate @rot_cursor

    @cursor\draw_center!
    g.pop!


  draw: (world) =>
    -- the under hud
    g.setPointSize 1
    for z=@hud_z+0.2,3,0.2
      world.space\draw_at_z z, ->
        g.points unpack @player_pos

    t = love.timer.getTime!
    px, py = 2 * math.cos(3 + t*1.1), 2 * math.sin(t)

    frame_depth = {
      [0]: 0.05
      [1]: 0.09
      [2]: 0.10
    }

    for frame=2,0,-1
      world.space\draw_at_z frame_depth[frame] + @player_z, ->
        g.push!
        g.translate unpack @player_pos
        g.rotate @get_rotation! * 2 - world.space.world_rot
        @player_sprite\draw frame, -16 + px, -8 + py
        g.pop!

    @draw_hud world

{:Player, :Bullet}
