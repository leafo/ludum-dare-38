{graphics: g} = love

import Player from require "player"
import Enemy from require "enemy"
import GameSpace from require "game_space"
import Tunnel from require "tunnel"

import Anchor, HList, Label, Group from require "lovekit.ui"
import HBar from require "ui"

import LutShader from require "shader"

class Game
  tunnel_alpha: 255

  new: =>
    @viewport = EffectViewport {
      pixel_scale: true
      scale: GAME_CONFIG.scale
    }

    @space = GameSpace @viewport
    @tunnel = Tunnel @space
    @score = 0

    @player = Player!
    @particles = DrawList!

    import TestWave, TunnelWave, BankWave from require "wave"
    TutorialWave = require "waves.tutorial"

    @set_wave TunnelWave

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

    lut = imgfy "images/lut-ratro.png"
    @lut = LutShader lut.tex

  set_wave: (wave_cls) =>
    @space = GameSpace @viewport
    @tunnel = Tunnel @space

    @wave = wave_cls @
    @entities = DrawList!

    -- ensure nothing is locked
    @player.movement_locked = false
    @player.bullets_locked = false
    @player.missiles_locked = false

  on_show: =>
    AUDIO\play_music "theme"

  create_ui: =>
    @ui = Group {
      Anchor(
        @viewport.w / 2
        2
        Label ->
          status = if @space.scroll_speed > 3
            "tight"
          else
            hp = @player\health_p!
            if hp == 0
              "obliterated"
            elseif hp < 0.2
              "fatal"
            elseif hp < 0.5
              "critical"
            elseif hp < 1
              "damaged"
            else
              "neutral"

          "sphincter status: #{status}"
        "center"
        "top"
      )
      Anchor(
        @viewport.w / 2
        @viewport.h - 2

        with HBar!
          .p = 0
          .update = (b, dt) ->
            b.p = smooth_approach b.p, @player\health_p!, dt * 2

        "center"
        "bottom"
      )
    }


  -- mousepressed: (x, y) =>
  --   x, y = @viewport\unproject x, y
  --   x -= @viewport.w / 2
  --   y -= @viewport.h / 2

  --   import Explosion from require "particle"
  --   @particles\add Explosion @, 1, x, y
  --   -- @player\explode @

  -- mousemoved: (x,y) =>
  --   x, y = @viewport\unproject x, y
  --   x -= @viewport.w / 2
  --   y -= @viewport.h / 2

  --   @space.tunnel_dir_x = x
  --   @space.tunnel_dir_y = y

  draw: =>
    @viewport\apply!

    COLOR\pusha @tunnel_alpha
    @tunnel\draw @
    COLOR\pop!

    @entities\draw_sorted ((a, b) -> a.z > b.z), @

    g.setBlendMode "add"
    @particles\draw @
    g.setBlendMode "alpha"

    @player\draw @
    -- draw any hud on entities
    for e in *@entities
      continue unless e.alive and e.draw_hud
      e\draw_hud @

    @ui\draw! if @ui

    if @overlay_ui
      @overlay_ui\draw!

    @lut\render ->
      @viewport\pop!

  update: (dt) =>
    if CONTROLLER\downed "pause"
      @paused = not @paused

    return if @paused

    unless @ui
      @create_ui!

    for item in *@scene
      if obj = @[item]
        obj\update dt, @

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
