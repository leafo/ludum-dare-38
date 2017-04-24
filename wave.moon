

class Wave extends Sequence
  new: (fn) =>
    @active_enemies = {}
    pre = ->
      if @world.tunnel_alpha != 255
        tween @world, 0.2, {
          tunnel_alpha: 255
        }

      setfenv fn, getfenv!
      fn!

    super pre, {
      move: (e, x,y,z, t=0.5) ->
        cx, cy = e\center!

        tween {
          x: x and cx
          y: y and cy
          z: z and e.z
        }, t, { :x, :y, :z }, nil, (obj) ->
          c2x, c2y = e\center!
          e\move_center obj.x or c2x, obj.y or c2y
          e.z = obj.z or e.z

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

      speed: (s, t=3.0) ->
        import GameSpace from require "game_space"
        s or= GameSpace.scroll_speed

        if t == 0
          @world.space.scroll_speed = s
        else
          tween @world.space, t, {
            scroll_speed: s
          }

      roll: (dir) ->
        print "rolling", dir
        rot = @world.space.world_rot
        switch dir
          when "normal"
            tween @world.space, 1.0, {
              world_rot: 0
            }
          when "flip"
            tween @world.space, 1.0, {
              world_rot: math.pi
            }
          when "left"
            tween @world.space, 2.0, {
              world_rot: rot + math.pi*2
            }
            -- truncate
            @world.space.world_rot = rot
          when "right"
            tween @world.space, 2.0, {
              world_rot: rot - math.pi*2
            }
            -- truncate
            @world.space.world_rot = rot
          else
            error "unknown rol direction: #{dir}"

      enter_bg: (bg) ->
        bx, by = unpack pick_one(
          {nil, "down"}
          {"left", "up"}
          {"right", "up"}
        )

        parallel(
          -> bank bx, by
          -> speed 10
          ->
            wait 0.1
            @world.tunnel\set_bg bg
        )

        parallel(
          -> speed nil, 1.0
          -> bank "center", "center"
        )

        wait 1.0

      bank: (horiz, vert, speed=1) ->
        t = 1 / speed

        a = switch horiz
          when "left"
            -> tween @world.space, t, {
              world_rot: math.pi / 4
              tunnel_dir_x: -10
            }

          when "right"
            -> tween @world.space, t, {
              world_rot: -math.pi / 4
              tunnel_dir_x: 10
            }
          when "center"
            -> tween @world.space, t, {
              world_rot: 0
              tunnel_dir_x: 0
            }
          when nil
            nil -- no change
          else
            error "unknown bank #{horiz}"

        b = switch vert
          when "up"
            -> tween @world.space, t, {
              tunnel_dir_y: -15
            }

          when "down"
            -> tween @world.space, t, {
              tunnel_dir_y: 15
            }
          when "center"
            -> tween @world.space, t, {
              tunnel_dir_y: 0
            }
          when nil
            nil -- no change
          else
            error "unknown bank #{vert}"

        parallel(a, b)

      change_wave: (wave) ->
        tween @world, 0.2, {
          tunnel_alpha: 0
        }

        @world\set_wave wave

      wait_or_confirm: ->
        wait_for_one(
          -> wait 3
          -> wait_until -> CONTROLLER\is_down "one", "two"
        )
    }

  enemy: (x, y) =>
    difficulty = @difficulty or 1

    import Enemy, EnemyShield, EvilEnemy, EvilEnemyShield from require "enemy"


    difficulties = {
      [1]: {
        [Enemy]: 1
      }
      [3]: {
        [EnemyShield]: 1
        [Enemy]: 2
      }
      [4]: {
        [EvilEnemy]: 1
        [Enemy]: 1
      }
    }

    enemy_type = Enemy
    for d=difficulty,1,-1
      if probs = difficulties[d]
        enemy_type = pick_dist probs
        break

    with e = enemy_type @world, x, y
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
      wait 0.5
      @world.tunnel\set_bg "hole"

      wait 0.5
      @world.tunnel\set_bg "fields"


      print "switching to forever wave"
      ForeverWave = require "waves.forever"
      change_wave ForeverWave

class BankWave extends Wave
  new: (@world) =>
    super ->
      k = 0
      while true
        print "entering bg"
        enter_bg k % 2 == 0 and "hole" or "fields"
        roll "flip"
        k += 1

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


{:Wave, :ForeverWave, :TestWave, :TunnelWave, :BankWave}
