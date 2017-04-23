import Wave from require "wave"

class ForeverWave extends Wave
  new: (@world) =>
    super ->
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
              wait rand 0.8, 1.2
              e\shoot @world, @world.player

      )

      wait_for_enemies!
      change_wave require "waves.forever"

