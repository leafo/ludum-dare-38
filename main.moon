require "lovekit.all"

{graphics: g} = love

export DEBUG = false

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

approach_vector = (start, stop, dt) ->
  for i=1,2
    start[i] = smooth_approach start[i], stop[i], dt * 5

class GameSpace
  new: (@viewport) =>
    -- center is this box's center
    @aim_box = Box 0, 0, @viewport.w * 0.75, @viewport.h * 0.75
    @aim_box\move_center 0, 0

    @rot = 0

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

    g.scale scale, scale
    COLOR\push 255 * scale, 255 * scale, 255 * scale
    fn!
    COLOR\pop!
    g.pop!

  draw_outline: =>
    @draw_at_z 0, ->
      @aim_box\outline!

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

class Tunnel
  lazy hole: -> imgfy "images/hole.png"

  new: (@space) =>
    @offset = 0

  update: (dt) =>
    @offset += dt
    @offset -= 1 if @offset > 1

  draw: =>
    w = @hole\width! / 2
    h = @hole\height! / 2

    for z=10,0,-0.5
      z -= @offset
      @space\draw_at_z z, ->
        g.translate (love.math.noise(z) - 0.5) * 40, 0
        @hole\draw -w, -h

class Enemy extends Box
  w: 12
  h: 8
  alive: true
  is_enemy: true

  new: (x, y) =>
    super 0, 0, @w, @h
    @move_center x, y
    @z = 2

  update: (dt) =>
    @z -= dt
    true

  draw: (game) =>
    game.space\draw_at_z @z, ->
      COLOR\push 255, 100, 100 if @hit
      Box.draw @
      COLOR\pop! if @hit

  -- ensure z is close enough
  on_hit_by: (bullet) =>
    return unless bullet.alive
    return if @hit
    if math.abs(bullet.z - @z) < 0.4
      @hit = true

class Player
  aim_depth: 10
  aim_speed: 100
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

    p = math.max(math.min(@player_vel[1], 50), -50) / 50
    sign = p == 0 and 1 or p / math.abs(p)
    p = sign * math.abs(p)^2
    p * math.pi / 24

  shoot: (game) =>
    AUDIO\play "shoot"
    bx, by = unpack @actual_aim
    game.entities\add Bullet bx, by, 2
    @scale_cursor = 1 + random_normal!

  update: (dt, game) =>
    vec = CONTROLLER\movement_vector(dt) * @aim_speed
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

  draw: (game) =>
    game.space\draw_at_z 0, ->
      g.setPointSize 3
      g.points unpack @player_pos
      g.points unpack @actual_aim

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

class Game
  new: =>
    @viewport = EffectViewport {
      pixel_scale: true
      scale: GAME_CONFIG.scale
    }

    @space = GameSpace @viewport
    @tunnel = Tunnel @space

    @player = Player!
    @entities = DrawList!

    @seq = Sequence ->
      wait 2
      @entities\add Enemy @space.aim_box\random_point!
      again!

  draw: =>
    @viewport\apply!

    @tunnel\draw!
    @entities\draw_sorted ((a, b) -> a.z > b.z), @

    @player\draw @
    @space\draw_outline!

    -- g.print "score: 99999, shoot: #{CONTROLLER\is_down "one"}", 5, 3

    @viewport\pop!

  update: (dt) =>
    @seq\update dt
    @tunnel\update dt
    @entities\update dt, @
    @player\update dt, @

    grid = UniformGrid!

    for e in *@entities
      grid\add e

    for e in *@entities
      continue if e.is_enemy
      for other in *grid\get_touching e
        continue if other.is_bullet
        if other.on_hit_by
          other\on_hit_by e

    if CONTROLLER\tapped "one"
      @player\shoot @


love.load = ->
  fonts = {
    default: load_font "images/font.png",
      [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&%]]
  }

  g.setFont fonts.default
  g.setBackgroundColor 50, 50, 50

  export CONTROLLER = Controller GAME_CONFIG.keys, "auto"
  export DISPATCHER = Dispatcher -> Game!

  DISPATCHER\bind love

  export AUDIO = Audio "sound"

  AUDIO\preload {
    "shoot"
  }


