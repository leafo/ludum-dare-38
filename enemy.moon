class Enemy extends Box
  w: 12
  h: 8
  alive: true
  is_enemy: true

  new: (x, y) =>
    super 0, 0, @w, @h
    @move_center x, y
    @z = 2

  update: (dt) =>
    @z -= dt
    true

  draw: (game) =>
    game.space\draw_at_z @z, ->
      COLOR\push 255, 100, 100 if @hit
      Box.draw @
      COLOR\pop! if @hit

  -- ensure z is close enough
  on_hit_by: (bullet) =>
    return unless bullet.alive
    return if @hit
    if math.abs(bullet.z - @z) < 0.4
      @hit = true

{:Enemy}
