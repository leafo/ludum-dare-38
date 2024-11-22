require "lovekit.all"

-- if pcall(-> require"inotify")
--   require "lovekit.reloader"

{graphics: g} = love

export DEBUG = false

load_font = (img_path, chars) ->
  with g.newImageFont img_path, chars
    \setFilter "nearest", "nearest"

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
  export DISPATCHER = Dispatcher -> Title!
  DISPATCHER.default_transition = FadeTransition

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

  DISPATCHER\bind love

