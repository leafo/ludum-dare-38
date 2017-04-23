require "lovekit.all"

if pcall(-> require"inotify")
  require "lovekit.reloader"

{graphics: g} = love

export DEBUG = false

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

import Game from require "game"
import Title from require "title"

love.load = ->
  fonts = {
    default: load_font "images/font.png",
      [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&%]]
  }

  g.setFont fonts.default
  g.setBackgroundColor 50, 50, 50

  export CONTROLLER = Controller GAME_CONFIG.keys, "auto"
  -- export DISPATCHER = Dispatcher -> Game!
  export DISPATCHER = Dispatcher -> Title!
  DISPATCHER.default_transition = FadeTransition

  DISPATCHER\bind love

  export AUDIO = Audio "sound"

  AUDIO\preload {
    "explode"
    "lock"
    "locking"
    "missile"
    "notarget"
    "shoot"
    "enemy_hit"
    "player_hit"
    "start"
  }


