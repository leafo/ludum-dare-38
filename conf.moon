export GAME_CONFIG = {
  viewport_width: 220
  viewport_height: 130

  scale: 4
  keys: {
    confirm: { "x", " ", joystick: {1,3,5} }
    cancel: { "c", joystick: 2 }


    quit: { "escape" }

    one: { "x", joystick: {1, 3, 5} }
    two: { "c", joystick: {2, 4, 6} }

    up: "up"
    down: "down"
    left: "left"
    right: "right"

    pause: { "p", joystick: 8 }
  }
}

love.conf = (t) ->
  t.window.width = GAME_CONFIG.viewport_width * GAME_CONFIG.scale
  t.window.height = GAME_CONFIG.viewport_height * GAME_CONFIG.scale

  t.title = "intestines shooter"
  t.author = "leafo"
