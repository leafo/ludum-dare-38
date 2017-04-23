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

class Missile extends Box
  lazy sprite: -> imgfy "images/bullet_green.png"

  alive: true
  is_bullet: true
  speed: 1

  new: (x,y, @z, @target, world) =>
    super 0, 0, @sprite\width!, @sprite\height!
    @vel = Vec2d(0, 0)
    @move_center x, y

    import Smoke from require "particle"

    @seq = Sequence ->
      k = 1
      while true
        world.particles\add Smoke world, @z, @center!
        wait 0.05

  draw: (world) =>
    world.space\draw_at_z @z, ->
      @sprite\draw @x, @y


  update: (dt) =>
    @seq\update dt
    @move unpack @vel * dt

    x,y = @center!
    tx, ty = @target\center!

    x = smooth_approach x, tx, dt * 5
    y = smooth_approach y, ty, dt * 5

    @move_center x, y

    @z += dt * @speed
    @z < 3 and @target.alive

class Player
  aim_depth: 10
  aim_speed: 200
  scale_cursor: 1
  rot_cursor: 0

  lazy cursor: -> imgfy "images/cursor.png"
  lazy cursor_center: -> imgfy "images/cursor_center.png"
  lazy lock_on_sprite: -> imgfy "images/lock_on.png"

  lazy player_sprite: ->
    Spriter "images/player.png", 64, 16

  new: =>
    @aim_pos = Vec2d!
    @player_pos = Vec2d!
    @player_vel = Vec2d!
    @player_z = -0.1
    @hud_z = 0.2

    @locked = {}
    @seqs = DrawList!

  move_aim: (space, dx, dy) =>
    @aim_pos\move dx, dy
    @aim_pos = space.aim_box\clamp_vector @aim_pos

  center: =>
    unpack @player_pos

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

  check_lock: (world, grid) =>
    hitbox = Box(0, 0, 20, 20)\move_center unpack @player_pos
    for e in *grid\get_touching hitbox
      continue unless e.alive
      continue unless e.is_enemy
      continue if @locked[e]
      AUDIO\play "lock"
      @locked[e] = true

  shoot_missile: (world, target) =>
    return unless target and target.alive
    AUDIO\play "missile"
    bx, by = unpack @player_pos
    world.entities\add Missile bx, by, @player_z, target, world
    @rot_cursor = math.pi

  fire_lock_ons: (world) =>
    count = 0

    targets = for target in pairs @locked
      continue unless target.alive
      count += 1
      target

    @locked = {}

    if count == 0
      @scale_cursor = 0.5
      AUDIO\play "notarget"
      return

    @seqs\add Sequence ->
      for target in *targets
        continue if target.z <= @player_z
        @shoot_missile world, target
        wait 0.1

  update: (dt, world) =>
    @locking = CONTROLLER\is_down "two"

    @seqs\update dt

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

    cursor_size = if @locking then 1.2 else 1

    if @scale_cursor != cursor_size
      @scale_cursor = smooth_approach @scale_cursor, cursor_size, dt * 2

    target_rot = if @locking then -math.pi / 2 else 0

    if @rot_cursor != target_rot
      @rot_cursor = smooth_approach @rot_cursor, target_rot, dt * 6

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

    g.scale @scale_cursor, @scale_cursor
    g.rotate @rot_cursor

    @cursor\draw_center!
    g.pop!

    -- draw lock ons
    for target in pairs @locked
      continue unless target.alive
      tx, ty = target\center!
      x, y = world.space\project tx, ty, target.z
      g.push!
      g.translate x, y
      g.rotate love.timer.getTime!
      @lock_on_sprite\draw_center!
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

    sw = @player_sprite.cell_w / 2
    sh = @player_sprite.cell_h / 2

    for frame=2,0,-1
      world.space\draw_at_z frame_depth[frame] + @player_z, ->
        g.push!
        g.translate unpack @player_pos
        g.rotate @get_rotation! * 2 - world.space.world_rot
        @player_sprite\draw frame, -sw + px, -sh + py
        g.pop!

    @draw_hud world

{:Player, :Bullet}
