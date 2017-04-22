{graphics: g} = love

approach_vector = (start, stop, dt) ->
  for i=1,2
    start[i] = smooth_approach start[i], stop[i], dt * 5

class Bullet extends Box
  lazy sprite: -> imgfy "images/bullet.png"
  alive: true
  is_bullet: true

  new: (x, y, @speed) =>
    super 0, 0, @sprite\width!, @sprite\height!
    @move_center x, y
    @z = -0.5

  update: (dt) =>
    @z += dt * @speed
    @z < 3

  draw: (game) =>
    game.space\draw_at_z @z, ->
      @sprite\draw @x, @y

class Player
  aim_depth: 10
  aim_speed: 200
  scale_cursor: 1

  lazy cursor: -> imgfy "images/cursor.png"
  lazy cursor_center: -> imgfy "images/cursor_center.png"

  new: =>
    @aim_pos = Vec2d!
    @actual_aim = Vec2d!
    @player_pos = Vec2d!
    @player_vel = Vec2d!

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

  shoot: (game) =>
    AUDIO\play "shoot"
    bx, by = unpack @actual_aim
    game.entities\add Bullet bx, by, 2
    @scale_cursor = 1 + random_normal!

  update: (dt, game) =>
    vec = CONTROLLER\movement_vector dt
    vec *= @aim_speed

    @move_aim game.space, unpack vec

    px, py = unpack @player_pos

    approach_vector @actual_aim, @aim_pos, dt
    approach_vector @player_pos, @aim_pos, dt / 2

    @player_vel = Vec2d(
      (@player_pos[1] - px) / dt
      (@player_pos[2] - py) / dt
    )

    if @scale_cursor > 1
      @scale_cursor = smooth_approach @scale_cursor, 1, dt * 2

    game.space.rot = @get_rotation!
    game.space.tilt = -(@player_pos[2] / game.viewport.h) * 2

  draw: (game) =>
    game.space\draw_at_z 0, ->
      g.setPointSize 3
      -- g.points unpack @player_pos

      @cursor_center\draw unpack @actual_aim - Vec2d(@cursor_center\width!, @cursor_center\height!) / 2

      g.push!
      g.translate unpack @aim_pos
      g.scale @scale_cursor, @scale_cursor
      @cursor\draw -@cursor\width!/2, -@cursor\height!/2
      g.pop!


    g.setPointSize 1
    for z=0,3,0.2
      game.space\draw_at_z z, ->
        g.points unpack @actual_aim

{:Player, :Bullet}
