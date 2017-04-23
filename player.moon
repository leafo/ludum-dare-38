{graphics: g} = love

approach_vector = (start, stop, dt) ->
  for i=1,2
    start[i] = smooth_approach start[i], stop[i], dt * 5

class Bullet extends Box
  lazy sprite: -> imgfy "images/bullet_small.png"
  alive: true
  is_bullet: true
  speed: 2
  damage: 1

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
  damage: 4

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

class Player extends Box
  aim_depth: 10
  aim_speed: 200
  scale_cursor: 1
  rot_cursor: 0
  time: 0
  locked: false
  bullets_fired: 0
  missiles_fired: 0
  barrages_fired: 0

  w: 25
  h: 8

  lazy cursor: -> imgfy "images/cursor.png"
  lazy cursor_center: -> imgfy "images/cursor_center.png"
  lazy lock_on_sprite: -> imgfy "images/lock_on.png"

  lazy player_sprite: ->
    Spriter "images/player.png", 32, 16

  new: =>
    super!
    @aim_pos = Vec2d!
    @move_center 0, 0
    @player_vel = Vec2d!
    @player_z = -0.1
    @hud_z = 0.3

    @locked = {}
    @seqs = DrawList!
    @effects = EffectList @

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
    @bullets_fired += 1
    AUDIO\play "shoot"
    bx, by = @center!
    world.entities\add Bullet bx, by, @player_z
    @scale_cursor = 1 + random_normal!

  check_lock: (world, grid) =>
    hitbox = Box(0, 0, 20, 20)\move_center @center!

    for e in *grid\get_touching hitbox
      continue unless e.alive
      continue unless e.is_enemy
      continue if @locked[e]
      AUDIO\play "lock"
      @locked[e] = true

  shoot_missile: (world, target) =>
    return unless target and target.alive
    @missiles_fired += 1
    AUDIO\play "missile"
    bx, by = @center!
    world.entities\add Missile bx, by, @player_z, target, world
    @rot_cursor = math.pi

  notarget: =>
    @scale_cursor = 0.5
    AUDIO\play "notarget"

  fire_lock_ons: (world) =>
    count = 0

    targets = for target in pairs @locked
      continue unless target.alive
      count += 1
      target

    @locked = {}

    if count == 0
      @notarget!
      return

    @barrages_fired += 1

    @seqs\add Sequence ->
      for target in *targets
        continue if target.z <= @player_z
        @shoot_missile world, target
        wait 0.1

  update: (dt, world) =>
    @time += dt

    if CONTROLLER\tapped "one"
      if @bullets_locked
        @notarget!
      else
        @shoot world

    @locking = not @missiles_locked and CONTROLLER\is_down "two"

    if CONTROLLER\downed "two"
      unless @missiles_locked
        AUDIO\play "locking"

    if CONTROLLER\tapped "two"
      @fire_lock_ons world

    @seqs\update dt
    @effects\update dt

    vec = if @movement_locked
      Vec2d!
    else
      CONTROLLER\movement_vector dt

    vec = Vec2d world.space\unproject_rot unpack vec

    vec *= @aim_speed

    @move_aim world.space, unpack vec

    px, py = @center!

    px2 = smooth_approach px, @aim_pos[1], dt * 5
    py2 = smooth_approach py, @aim_pos[2], dt * 5

    @move_center px2, py2

    @player_vel = Vec2d(
      (px2 - px) / dt
      (py2 - py) / dt
    )

    cursor_size = if @locking then 1.2 else 1

    if @scale_cursor != cursor_size
      @scale_cursor = smooth_approach @scale_cursor, cursor_size, dt * 2

    target_rot = if @locking then -math.pi / 2 else 0

    if @rot_cursor != target_rot
      @rot_cursor = smooth_approach @rot_cursor, target_rot, dt * 6

    world.space.rot = @get_rotation!
    world.space.xtilt = -(px2 / world.viewport.w)
    world.space.ytilt = -(py2 / world.viewport.h) * 2

  draw_hud: (world) =>
    space = world.space
    offset = space.offset

    t = offset - math.floor offset

    pt = pop_in(t, 2.0) / 4

    space\draw_at_z pt, ->
      COLOR\pusha (1 - t) * 128
      space.aim_box\outline!
      COLOR\pop!

    space\draw_at_z @hud_z, ->
      COLOR\pusha 128
      space.aim_box\outline!
      COLOR\pop!
      @cursor_center\draw_center @center!

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
    return if @dead

    -- the under hud
    g.setPointSize 1
    for z=@hud_z+0.2,3,0.2
      world.space\draw_at_z z, ->
        g.points @center!

    px, py = 2 * math.cos(3 + @time*1.1), 2 * math.sin(@time)

    t = @time * 3
    t = t - math.floor(t)

    frame_depth = {
      [0]: -0.02 - smoothstep(0, 1, t) / 10
      [1]: -0.02
      [2]: 0
      [3]: 0.02
    }

    sw = @player_sprite.cell_w
    sh = @player_sprite.cell_h / 2

    for frame=3,0,-1
      world.space\draw_at_z @player_z + frame_depth[frame], ->
        g.push!
        g.translate @center!
        g.rotate @get_rotation! * 2 - world.space.world_rot

        if frame == 0
          COLOR\pusha (1 - t) * 255
          g.setBlendMode "add"

        @effects\before!
        @player_sprite\draw frame, -sw + px, -sh + py
        @player_sprite\draw frame, sw + px, -sh + py, 0, -1, 1
        @effects\after!

        if frame == 0
          g.setBlendMode "alpha"
          COLOR\pop!

        g.pop!

    @draw_hud world

  on_hit_by: (bullet, world) =>
    return if @dying or @dead

    if math.abs(@player_z - bullet.z) < 0.1
      bullet.alive = false
      world.viewport\shake!
      @effects\add FlashEffect!
      @effects\add ShakeEffect!
      AUDIO\play "player_hit"

  explode: (world) =>
    return if @dying or @dead

    @dying = true
    world.viewport\shake!
    @effects\add BlowOutEffect 1.0, ->
      @dead = true

    x, y = @center!
    @seqs\add Sequence ->
      for i=1,5
        import Explosion from require "particle"

        world.particles\add Explosion(
          world
          @player_z
          x + random_normal! * 30
          y + random_normal! * 10
        )

        wait 0.2

    AUDIO\play "explode"

{:Player, :Bullet}
