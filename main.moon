require "lovekit.all"

{graphics: g} = love

export DEBUG = false

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

class GameSpace
  new: =>
    @aim_box = Box 0, GAME_CONFIG.viewport_width, GAME_CONFIG.viewport_height

class Player
  aim_depth: 10
  aim_speed: 100

  new: =>
    @aim_pos = Vec2d 30, 30
    @actual_aim = Vec2d 30, 30
    @player_pos = Vec2d 30, 30

  update: (dt) =>
    -- move the player towards where we're aiming

class Game
  lazy cursor: -> imgfy "images/cursor.png"

  new: =>
    @player = Player!
    @viewport = EffectViewport scale: GAME_CONFIG.scale


  draw: =>
    @viewport\apply!
    g.print "hello world", 10, 10
    @cursor\draw @cx, @cy

    @viewport\pop!

  update: (dt) =>
    vec = CONTROLLER\movement_vector(dt) * @player.aim_speed
    @player.aim_pos\move unpack vec

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

