{graphics: g} = love

import Explosion from require "particle"

class Enemy extends Box
  w: 12
  h: 8
  alive: true
  is_enemy: true

  new: (x, y) =>
    super 0, 0, @w, @h
    @move_center x, y
    @z = 2

  update: (dt, world) =>
    @z -= dt * world.space.scroll_speed / 3
    not @hit

  draw: (world) =>
    world.space\draw_at_z @z, ->
      COLOR\push 255, 100, 100 if @hit
      Box.draw @
      COLOR\pop! if @hit

  explode: (world) =>
    world.particles\add Explosion world, @z, @center!

  -- ensure z is close enough
  on_hit_by: (bullet, world) =>
    return unless bullet.alive
    return if @hit
    if math.abs(bullet.z - @z) < 0.2
      @explode world
      bullet.alive = false
      @hit = true

{:Enemy}
