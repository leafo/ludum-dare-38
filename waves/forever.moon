import Wave from require "wave"

class ForeverWave extends Wave
  new: (@world) =>
    super ->
      intro = ->
        show_box "entering intestine"
        wait_or_confirm!
        hide_box!

        enter_bg "hole"


      spinner = (x=0, y=0, radius=40) ->
        e = @enemy x, y
        wait rand 0.8, 1.5

        parallel(
          -> movez e, 0.5, 1
          ->
            while true
              deg = 0
              while deg < math.pi*2
                move(
                  e
                  x + math.cos(deg) * radius
                  y + math.sin(deg) * radius
                )
                deg += math.pi*2/4
        )


      while true
        spinner!

        -- parallel(
        --   unpack for {x,y} in *{
        --     {-30, -30}
        --     {30, -30}
        --     {30, 30}
        --     {-30, 30}
        --   }
        --     ->
        --       e = @enemy x, y
        --       wait rand 0.8, 1.5
        --       if e\active!
        --         movez e, 0.8, 1

        --       -- while e\active!
        --       --   wait rand 0.8, 1.2
        --       --   e\shoot @world, @world.player

        -- )

        wait_for_enemies!

