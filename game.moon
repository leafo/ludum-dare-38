{graphics: g} = love

import Player from require "player"
import Enemy from require "enemy"
import GameSpace from require "game_space"
import Tunnel from require "tunnel"

import Anchor, HList, Label from require "lovekit.ui"


import LutShader from require "shader"

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

    import TestWave, TunnelWave, BankWave from require "wave"
    TutorialWave = require "waves.tutorial"

    -- @wave = TestWave @
    -- @wave = TutorialWave @
    @wave = BankWave @

    @scene = {
      "viewport"
      "wave"
      "space"
      "tunnel"
      "player"
      "entities"
      "particles"
      "ui"
    }

    @ui = HList {
      x: 2, y: 2
      Label -> "e: #{#@entities}, p: #{#@particles}"
      Box 0, 0, 3,8
      Label -> "sphincter status: neutral"
    }

    lut = imgfy "images/lut-ratro.png"
    @lut = LutShader lut.tex

  on_show: =>
    AUDIO\play_music "theme"

  mousepressed: (x, y) =>
    x, y = @viewport\unproject x, y
    x -= @viewport.w / 2
    y -= @viewport.h / 2

    -- import Explosion from require "particle"
    -- @particles\add Explosion @, 1, x, y

    @player\explode @

  -- mousemoved: (x,y) =>
  --   x, y = @viewport\unproject x, y
  --   x -= @viewport.w / 2
  --   y -= @viewport.h / 2

  --   @space.tunnel_dir_x = x
  --   @space.tunnel_dir_y = y

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
    if @overlay_ui
      @overlay_ui\draw!

    @lut\render ->
      @viewport\pop!

  update: (dt) =>
    if CONTROLLER\downed "pause"
      @paused = not @paused

    return if @paused

    for item in *@scene
      @[item]\update dt, @

    if @overlay_ui
      @overlay_ui\update dt

    grid = UniformGrid!

    for e in *@entities
      grid\add e

    for e in *@entities
      continue if e.is_enemy
      for other in *grid\get_touching e
        continue if other.is_bullet
        if other.on_hit_by
          other\on_hit_by e, @

    -- check if player hit
    for other in *grid\get_touching @player
      continue unless other.is_enemy_bullet
      continue unless other.alive
      @player\on_hit_by other, @

    if @player.locking
      @player\check_lock @, grid


  get_closest_enemy: (z) =>
    enemies = [e for e in *@entities when e.alive and e.is_enemy and e.z >= z]
    table.sort enemies, (a, b) -> a.z < b.z
    enemies[1]

{:Game}
