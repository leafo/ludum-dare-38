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
    math.max 0.1, (10 - z) / 10

class Tunnel
  lazy hole: -> imgfy "images/hole.png"

  new: (@space) =>

  draw: =>
    w = @hole\width! / 2
    h = @hole\height! / 2

    for z=0,10
      print "drawing hole"
      g.push!
      scale = @space\scale_factor z
      g.scale scale, scale
      g.setColor 255 * scale, 255 * scale, 255 * scale
      @hole\draw -w, -h
      g.pop!

    g.setColor 255, 255, 255

class Player
  aim_depth: 10
  aim_speed: 100
  lazy cursor: -> imgfy "images/cursor.png"

  new: =>
    @aim_pos = Vec2d 30, 30
    @actual_aim = Vec2d 30, 30
    @player_pos = Vec2d 30, 30

  move_aim: (space, dx, dy) =>
    @aim_pos\move dx, dy
    @aim_pos = space.aim_box\clamp_vector @aim_pos

  update: (dt, game) =>
    vec = CONTROLLER\movement_vector(dt) * @aim_speed
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
    @player = Player!
    @space = GameSpace!
    @tunnel = Tunnel @space

    @viewport = EffectViewport {
      pixel_scale: true
      scale: GAME_CONFIG.scale
    }

  draw: =>
    @viewport\apply!
    g.print "score: 99999, shoot: #{CONTROLLER\is_down "one"}", 5, 3

    @tunnel\draw!
    
    @space.aim_box\outline!
    @player\draw @

    @viewport\pop!

  update: (dt) =>
    @space.aim_box\move_center @viewport\center!
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
