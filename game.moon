{graphics: g} = love

import Player from require "player"
import Enemy from require "enemy"
import GameSpace from require "game_space"
import Tunnel from require "tunnel"

import Anchor, HList, Label from require "lovekit.ui"

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
    @particles = DrawList!

    @seq = Sequence ->
      wait 2
      @entities\add Enemy @space.aim_box\random_point!
      again!

    @ui = HList {
      x: 2, y: 2
      Label -> "score: 0"
      Box 0, 0, 3,8
      Label -> "sphincter status: neutral"
    }

  mousepressed: (x, y) =>
    x, y = @viewport\unproject x, y
    x -= @viewport.w / 2
    y -= @viewport.h / 2

    import Explosion from require "particle"
    print x, y
    @particles\add Explosion @, 1, x, y

  draw: =>
    @viewport\apply!

    @tunnel\draw!
    @entities\draw_sorted ((a, b) -> a.z > b.z), @
    g.setBlendMode "add"
    @particles\draw @
    g.setBlendMode "alpha"

    @player\draw @
    @space\draw_outline!

    -- g.print "score: 99999, shoot: #{CONTROLLER\is_down "one"}", 5, 3
    @ui\draw!

    @viewport\pop!

  update: (dt) =>
    @seq\update dt
    @tunnel\update dt
    @entities\update dt, @
    @particles\update dt, @
    @player\update dt, @
    @ui\update dt

    grid = UniformGrid!

    for e in *@entities
      grid\add e

    for e in *@entities
      continue if e.is_enemy
      for other in *grid\get_touching e
        continue if other.is_bullet
        if other.on_hit_by
          other\on_hit_by e, @

    if CONTROLLER\tapped "one"
      @player\shoot @

{:Game}
