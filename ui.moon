
{graphics: g} = love

class HBar extends Box
  p: 0.5
  w: 100
  h: 12
  padding: 2

  draw: =>
    @outline!
    COLOR\push {255, 100, 100, 128}
    full_width = @w - @padding * 2
    g.rectangle "fill", @x + @padding, @y + @padding,
      full_width * @p, @h - @padding * 2
    COLOR\pop!


{:HBar}
