require "lovekit.all"

{graphics: g} = love

export DEBUG = false

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars


class GameSpace
  new: =>
    @aim_box = Box 0, 0,
      GAME_CONFIG.viewport_width * 0.75, GAME_CONFIG.viewport_height * 0.75

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

  update: (dt) =>
    -- move the player towards where we're aiming

  draw: (game) =>
    @cursor\draw unpack @aim_pos - Vec2d(@cursor\width!, @cursor\height!) / 2

class Game

  new: =>
    @player = Player!
    @space = GameSpace!

    @viewport = EffectViewport scale: GAME_CONFIG.scale

  draw: =>
    @viewport\apply!
    g.print "score: 99999, shoot: #{CONTROLLER\is_down "one"}", 5, 3
    
    @space.aim_box\outline!
    @player\draw @

    @viewport\pop!

  update: (dt) =>
    vec = CONTROLLER\movement_vector(dt) * @player.aim_speed
    @player\move_aim @space, unpack vec
    @space.aim_box\move_center @viewport\center!

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

