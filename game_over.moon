{graphics: g} = love
import RevealLabel, Anchor, Border from require "lovekit.ui"

class GameOver
  time: 0

  new: (@game) =>
    @viewport = EffectViewport {
      pixel_scale: true
      scale: GAME_CONFIG.scale
    }

  on_show: =>
    cx, cy = @viewport\center!
    @ui = Anchor cx, cy, Border(
      with RevealLabel("game over. press shoot to return to title. you score #{math.floor @game.score}", 0, 0)
        \set_max_width 200

      padding: 10, background: { 0,0,0,200 }
    ), "center", "bottom"

    @seq = Sequence ->
      wait 0.5
      wait_until -> CONTROLLER\downed "one"
      import Title from require "title"
      DISPATCHER\reset Title!

  draw: =>
    @viewport\apply!
    @ui\draw!
    @viewport\pop!

  update: (dt) =>
    @seq\update dt if @seq
    @ui\update dt if @ui

{:GameOver}
