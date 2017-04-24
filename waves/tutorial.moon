
import Wave from require "wave"

class TutorialWave extends Wave
  new: (@world) =>
    super ->
      DID_TUTORIAL = true
      unless AUDIO.current_music == "title"
        AUDIO\play_music "title"

      @world.player.movement_locked = true
      @world.player.bullets_locked = true
      @world.player.missiles_locked = true
      @world.space.scroll_speed = 5

      wait 1.0

      show_box "engaging training"
      speed!

      hide_box!
      wait 1.0

      @world.player.movement_locked = false
      show_box "use arrows or gamepad to move"

      wait_until ->
        not @world.player.player_vel\is_zero!

      show_box "good job!"
      wait 2.0
      hide_box!
      wait 0.5
      @world.player.bullets_locked = false

      show_box "press button 1 or 'x' to fire bullets"
      wait_for_player_to_shoot!
      hide_box!

      wait 3.0

      show_box "take out these enemies"
      wait 1.0

      wait_for_one(
        -> wait 3
        -> wait_for_player_to_shoot!
      )

      hide_box!

      parallel(
        unpack for {x,y} in *{
          {-30, -30}
          {30, -30}
          {30, 30}
          {-30, 30}
        }
          ->
            e = @enemy x, y
            wait rand 0.8, 1.5
            if e\active!
              movez e, 0.8, 1
      )

      wait_for_enemies!
      show_box "nice shooting"
      wait_or_confirm!

      while true
        @world.player.missiles_locked = false
        @world.player.bullets_locked = true

        b = @world.player.barrages_fired
        show_box "hold button 2 or 'c' to lock on missiles"
        wait_or_confirm!

        show_box "take out all enemies with one barrage"
        wait_or_confirm!
        hide_box!

        parallel(
          unpack for {x,y} in *{
            {-60, 0}
            {-30, 0}
            {0, 0}
            {30, 0}
            {60, 0}
          }
            ->
              e = @enemy x, y
              wait rand 0.8, 1.5
              if e\active!
                movez e, 0.8, 1
        )

        wait_for_enemies!

        if b + 1 == @world.player.barrages_fired
          break
        else
          show_box "oops, lets try that again"
          wait_or_confirm!

      @world.player.missiles_locked = false
      @world.player.bullets_locked = false

      show_box "excellent... you're ready"
      wait_or_confirm!
      hide_box!
      parallel(
        -> roll "left"
        -> speed 10
      )

      ForeverWave = require "waves.forever"
      change_wave ForeverWave

