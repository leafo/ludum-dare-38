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

  scale_factor: (z) =>
    -- z of 0 is screen depth
    math.min 3, 1 / (z + 1)

  draw_at_z: (z, fn) =>
    g.push!
    scale = @scale_factor z
    g.translate @viewport.w / 2, @viewport.h / 2

    g.scale scale, scale
    g.setColor 255 * scale, 255 * scale, 255 * scale
    fn!
    g.setColor 255,255,255
    g.pop!

  draw_outline: =>
    @draw_at_z 0, ->
      @aim_box\outline!

class Bullet
  lazy sprite: -> imgfy "images/bullet.png"
  alive: true

  new: (x, y, @speed) =>
    @pos = Vec2d x, y
    @z = -0.5

  update: (dt) =>
    @z += dt * @speed
    @z < 3

  draw: (game) =>
    w = @sprite\width! / 2
    h = @sprite\height! / 2

    game.space\draw_at_z @z, ->
      @sprite\draw -w + @pos[1], -h + @pos[2]

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

    g.setColor 255, 255, 255

class Player
  aim_depth: 10
  aim_speed: 100
  lazy cursor: -> imgfy "images/cursor.png"

  new: =>
    @aim_pos = Vec2d!
    @actual_aim = Vec2d!
    @player_pos = Vec2d!

  move_aim: (space, dx, dy) =>
    @aim_pos\move dx, dy
    @aim_pos = space.aim_box\clamp_vector @aim_pos

  update: (dt, game) =>
    vec = CONTROLLER\movement_vector(dt) * @aim_speed
    -- print vec
    @move_aim game.space, unpack vec

    approach_vector @actual_aim, @aim_pos, dt
    approach_vector @player_pos, @aim_pos, dt / 2

  draw: (game) =>
    game.space\draw_at_z 0, ->
      g.setPointSize 3
      g.points unpack @player_pos
      g.points unpack @actual_aim
      @cursor\draw unpack @aim_pos - Vec2d(@cursor\width!, @cursor\height!) / 2

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

  draw: =>
    @viewport\apply!

    @tunnel\draw!
    @entities\draw @
    @player\draw @
    @space\draw_outline!

    g.print "score: 99999, shoot: #{CONTROLLER\is_down "one"}", 5, 3

    @viewport\pop!

  update: (dt) =>
    @tunnel\update dt
    @entities\update dt, @
    @player\update dt, @

    if CONTROLLER\tapped "one"
      bx, by = unpack @player.actual_aim
      @entities\add Bullet bx, by, 2

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

