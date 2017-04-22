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
      while true
        @entities\add Enemy @space.aim_box\random_point!
        wait 1

    @scene = {
      "seq", "space", "tunnel", "player", "entities", "particles", "ui"
    }

    @ui = HList {
      x: 2, y: 2
      Label -> "e: #{#@entities}, p: #{#@particles}"
      Box 0, 0, 3,8
      Label -> "sphincter status: neutral"
    }

  mousepressed: (x, y) =>
    x, y = @viewport\unproject x, y
    x -= @viewport.w / 2
    y -= @viewport.h / 2

    import Explosion from require "particle"
    @particles\add Explosion @, 1, x, y

  draw: =>
    @viewport\apply!

    @tunnel\draw @
    @entities\draw_sorted ((a, b) -> a.z > b.z), @

    g.setBlendMode "add"
    @particles\draw @
    g.setBlendMode "alpha"

    @player\draw @
    -- draw any hud on entities
    for e in *@entities
      continue unless e.alive and e.draw_hud
      e\draw_hud @


    @ui\draw!

    @viewport\pop!

  update: (dt) =>
    for item in *@scene
      @[item]\update dt, @

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

    if CONTROLLER\tapped "two"
      @player\fire_lock_ons @

    if CONTROLLER\is_down "two"
      @player.locking = true
      @player\check_lock @, grid


  get_closest_enemy: (z) =>
    enemies = [e for e in *@entities when e.alive and e.is_enemy and e.z >= z]
    table.sort enemies, (a, b) -> a.z < b.z
    enemies[1]

{:Game}
