{graphics: g} = love

import RevealLabel, Anchor, Border from require "lovekit.ui"

class Title
  lazy bg: -> imgfy "images/title.png"
  time: 0
  ui_alpha: 255

  new: =>
    @viewport = EffectViewport {
      pixel_scale: true
      scale: GAME_CONFIG.scale
    }

  on_show: =>
    @ui_alpha = 255
    cx, cy = @viewport\center!
    @ui = Anchor cx, @viewport.h - 10, Border(
      with RevealLabel("press 'x' or button 1 to start", 0, 0)
        \set_max_width 200

      padding: 10, background: { 0,0,0,200 }
    ), "center", "bottom"

    AUDIO\play_music "title"

    @seq = Sequence ->
      wait 0.5
      wait_until -> CONTROLLER\downed "one"
      AUDIO\play "start"
      tween @, 1.0, ui_alpha: 0

      import Game from require "game"
      DISPATCHER\push Game!

  draw: =>
    @viewport\apply!
    @bg\draw 0,0
    g.push!
    COLOR\pusha @ui_alpha
    g.translate 0, 3 * math.sin @time
    @ui\draw!
    COLOR\pop!
    g.pop!
    @viewport\pop!

  update: (dt) =>
    @time += dt
    @ui\update dt if @ui
    @seq\update dt if @seq

{:Title}
