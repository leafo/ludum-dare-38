
import Enemy from require "enemy"

class Wave extends Sequence
  enemy: (x, y) =>
    with e = Enemy @world, space.aim_box\random_point!
      @world.entities\add e

  new: (@world) =>
    space = @world.space

    super ->
      while true
        @enemy space.aim_box\random_point!
        wait 1

{:Wave}
