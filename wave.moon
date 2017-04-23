
import Enemy from require "enemy"

class Wave extends Sequence
  new: (fn) =>
    @active_enemies = {}
    super fn, {
      move: (e, x,y,z, t=0.5) ->
        cx, cy = e\center!
        tween {
          x: cx
          y: cy
          z: e.z
        }, t, { :x, :y, :z }, nil, (obj) ->
          e\move_center obj.x, obj.y
          e.z = obj.z

      movez: (e, z, t=0.5) ->
        tween e, t, { :z }

      wait_for_enemies: ->
        wait_until ->
          not next @active_enemies

      wait_for_player_to_shoot: ->
        b = @world.player.bullets_fired
        wait_until -> @world.player.bullets_fired > b

      show_box: (text) ->
        import RevealLabel, Anchor, Border from require "lovekit.ui"
        cx, cy = @world.viewport\center!

        done = false

        @world.overlay_ui = Anchor cx, cy, Border(
          with RevealLabel(text, 0, 0, -> done = true)
            \set_max_width 50

          padding: 10, background: { 0,0,0,200 }
        ), "center"

        wait_until -> done

      hide_box: ->
        @world.overlay_ui = nil
    }

  enemy: (x, y) =>
    with e = Enemy @world, x, y
      @world.entities\add e
      table.insert @active_enemies, e

  -- clear out the enemies array
  update: (...) =>
    refresh = false
    for e in *@active_enemies
      unless e.alive
        refresh = true
        break

    if refresh
      @active_enemies = [e for e in *@active_enemies when e.alive]

    super ...


class ForeverWave extends Wave
  new: (@world) =>
    space = @world.space
    super ->
      while true
        @enemy space.aim_box\random_point!
        wait 1


class TunnelWave extends Wave
  new: (@world) =>
    super ->
      while true
        wait 0.5
        @world.tunnel\set_bg "hole"

        wait 0.5
        @world.tunnel\set_bg "fields"

class TestWave extends Wave
  new: (@world) =>
    space = @world.space
    w = @world.viewport.w
    h = @world.viewport.h

    import GameSpace from require "game_space"

    super ->

      rots = {
        math.pi/4
        0
        -math.pi/4
        0
      }

      iter = 0
      while true
        parallel(
          unpack for i=1,4
            ->
              x = -30 + ((i - 1) * 30)
              e = @enemy x, -20 * math.sin(x)
              wait rand 0.8, 1.2
              if e\active!
                movez e, 0.8, 1
        )

        wait_for_enemies!

        e = @enemy 0, 0

        while e\active!
          wait rand 0.8, 1.2
          e\shoot @world, @world.player

        wait_for_enemies!

        -- tween @world.space, 1.0, {
        --   world_rot: rots[(iter % #rots) + 1]
        --   tunnel_dir_x: -10
        -- }

        iter += 1


{:Wave, :ForeverWave, :TestWave, :TunnelWave}
