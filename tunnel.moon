
{graphics: g} = love

class Tunnel
  lazy hole: -> imgfy "images/hole.png"

  new: (@space) =>

  update: (dt) =>

  draw: (world) =>
    w = @hole\width! / 2
    h = @hole\height! / 2

    offset = world.space.offset
    offset -= math.floor offset

    for z=10,0,-0.5
      z -= offset
      @space\draw_at_z z, ->
        g.translate (love.math.noise(z) - 0.5) * 40, 0
        @hole\draw -w, -h


{:Tunnel}
