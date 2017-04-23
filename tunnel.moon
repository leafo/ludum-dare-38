
{graphics: g} = love

class Tunnel
  lazy backgrounds: -> {
    hole: imgfy "images/hole.png"
    fields: imgfy "images/hole2.png"
    hair: imgfy "images/hair.png"
    grid: imgfy "images/grid.png"
  }

  new: (@space) =>
    @bg = @backgrounds.fields
    @bg_changes = {}

  update: (dt) =>
    -- check if we can pop changes since we've passed them
    while @bg_changes[1]
      offset, bg = unpack @bg_changes[1]
      if @space.offset > offset + 10
        @bg = bg
        table.remove @bg_changes, 1
      else
        break

  set_bg: (name) =>
    bg = assert @backgrounds[name]
    table.insert @bg_changes, { @space.offset + 10, bg }

  bg_for_offset: (z) =>
    if @bg_changes[1]
      for i=#@bg_changes,1,-1
        offset, bg = unpack @bg_changes[i]
        if z >= offset
          return bg

    @bg

  draw: =>
    w = @bg\width! / 2
    h = @bg\height! / 2

    offset = @space.offset
    offset -= math.floor offset

    for z=10,0,-0.5
      z -= offset
      @space\draw_at_z z, ->
        g.translate (love.math.noise(z) - 0.5) * 40, 0

        bg = @bg_for_offset @space.offset + z
        bg\draw -w, -h


{:Tunnel}
