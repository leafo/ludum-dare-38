
import Player from require "player"
import Enemy from require "enemy"
import GameSpace from require "game_space"
import Tunnel from require "tunnel"

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

    @seq = Sequence ->
      wait 2
      @entities\add Enemy @space.aim_box\random_point!
      again!

  draw: =>
    @viewport\apply!

    @tunnel\draw!
    @entities\draw_sorted ((a, b) -> a.z > b.z), @

    @player\draw @
    @space\draw_outline!

    -- g.print "score: 99999, shoot: #{CONTROLLER\is_down "one"}", 5, 3

    @viewport\pop!

  update: (dt) =>
    @seq\update dt
    @tunnel\update dt
    @entities\update dt, @
    @player\update dt, @

    grid = UniformGrid!

    for e in *@entities
      grid\add e

    for e in *@entities
      continue if e.is_enemy
      for other in *grid\get_touching e
        continue if other.is_bullet
        if other.on_hit_by
          other\on_hit_by e

    if CONTROLLER\tapped "one"
      @player\shoot @

{:Game}