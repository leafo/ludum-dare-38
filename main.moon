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
  new: =>
    @aim_box = Box 0, 0,
      GAME_CONFIG.viewport_width * 0.75, GAME_CONFIG.viewport_height * 0.75

  scale_factor: (z) =>
    math.min 2, 1 / z

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
      g.push!
      scale = @space\scale_factor z
      g.translate @space.aim_box\center!

      g.translate love.math.noise(z) * 10, 0

      g.scale scale, scale
      g.setColor 255 * scale, 255 * scale, 255 * scale
      @hole\draw -w, -h
      g.pop!

    g.setColor 255, 255, 255

class Player
  aim_depth: 10
  aim_speed: 100
  lazy cursor: -> imgfy "images/cursor.png"

  new: (center) =>
    @aim_pos = Vec2d unpack center
    @actual_aim = Vec2d unpack center
    @player_pos = Vec2d unpack center

  move_aim: (space, dx, dy) =>
    @aim_pos\move dx, dy
    @aim_pos = space.aim_box\clamp_vector @aim_pos

  update: (dt, game) =>
    vec = CONTROLLER\movement_vector(dt) * @aim_speed
    print vec

    @move_aim game.space, unpack vec

    approach_vector @actual_aim, @aim_pos, dt
    approach_vector @player_pos, @aim_pos, dt / 2

  draw: (game) =>
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

    @space = GameSpace!
    @space.aim_box\move_center @viewport\center!
    @tunnel = Tunnel @space

    @player = Player Vec2d @space.aim_box\center!

  draw: =>
    @viewport\apply!
    g.print "score: 99999, shoot: #{CONTROLLER\is_down "one"}", 5, 3

    @tunnel\draw!
    
    @space.aim_box\outline!
    @player\draw @

    @viewport\pop!

  update: (dt) =>
    @tunnel\update dt
    @player\update dt, @

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

