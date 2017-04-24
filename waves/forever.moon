import Wave from require "wave"

class ForeverWave extends Wave
  new: (@world) =>
    @difficulty = 4

    super ->
      @current_bg = "fields"

      intro = ->
        show_box "entering intestine"
        wait_or_confirm!
        hide_box!
        enter_bg "hole"
        @current_bg = "hole"

      spinner = (x=0, y=0, radius=40) ->
        e = @enemy x, y
        wait rand 0.2, 0.8

        dir = pick_one 1, -1

        parallel(
          -> movez e, 0.5, 1
          ->
            while true
              deg = 0
              while deg < math.pi*2 and deg > -math.pi*2
                move(
                  e
                  x + math.cos(deg) * radius
                  y + math.sin(deg) * radius
                )
                deg += dir * math.pi*2/4
        )

      dual_spinner = ->
        parallel(
          ->
            spinner -40
          ->
            wait rand 0.2, 0,5
            spinner 40
        )

      quad = ->
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

              while e\active!
                if chance 0.25 * @difficulty
                  wait rand 0.8, 1.2
                  e\shoot @world, @world.player

                wait rand 2.0, 2.5
        )

      random = (count=@difficulty)->
        parallel unpack for i=1,count
          ->
            wait rand 0.4, 0.8
            e = @enemy @world.space.aim_box\random_point!
            wait rand 0.8, 1.5
            if e\active!
              movez e, rand 0.6, 0.9

            while e\active!
              action = pick_dist {
                nothing: 5
                move: 1
                shoot: 1 * @difficulty
              }

              switch action
                when "move"
                  move e, @world.space.aim_box\random_point!
                when "shoot"
                  wait rand 0.8, 1.2
                  e\shoot @world, @world.player

      -- intro!
      while true
        print "Starting difficulty", @difficulty
        -- spinner!
        for i=1, 1 + math.min 5, math.floor @difficulty / 2
          random!

        opts = {
          hole: 1
          fields: 1
          hair: 1
          grid: @difficulty > 2 and 1
        }

        opts[@current_bg] = nil

        next_bg = pick_dist opts

        enter_bg next_bg
        @current_bg = next_bg
        @difficulty += 1

