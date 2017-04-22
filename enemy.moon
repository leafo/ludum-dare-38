{graphics: g} = love

import Explosion, ZImageParticle from require "particle"

class LaserParticle extends ZImageParticle
  life: 0.5
  ad_left: 0.05
  lazy sprite: -> imgfy "images/enemy_bullet.png"

  new: (...) =>
    super ...
    @dz = 0
    @dscale = 1

class EnemyBullet extends Box
  lazy sprite: -> imgfy "images/enemy_bullet.png"
  is_enemy_bullet: true

  w: 8
  h: 8

  new: (world, x, y, @z) =>
    super!
    @dz = -world.space.scroll_speed*1.5 + (random_normal! - 0.5)

    @tx, @ty = world.player\center!

    @move_center x,y
    @seq = Sequence ->
      while true
        wait 0.02
        world.particles\add LaserParticle world, @z, @center!

  update: (dt) =>
    @z += @dz * dt
    @seq\update dt if @seq

    if @tx and @ty
      x, y = @center!
      x = smooth_approach x, @tx, dt * 3
      y = smooth_approach y, @ty, dt * 3
      @move_center x, y

    true

  draw: (world) =>
    world.space\draw_at_z @z, ->
      g.setBlendMode "add"
      @sprite\draw @x, @y
      g.setBlendMode "alpha"

class Enemy extends Box
  w: 12
  h: 8
  alive: true
  is_enemy: true

  new: (world, x, y) =>
    super 0, 0, @w, @h
    @move_center x, y
    @z = 2

    @seq = Sequence ->
      wait 1.0
      @shoot world, world.player
      @seq = nil

  update: (dt, world) =>
    @z -= dt * world.space.scroll_speed / 3
    @seq\update dt if @seq
    not @hit and @z > -1

  draw: (world) =>
    world.space\draw_at_z @z, ->
      COLOR\push 255, 100, 100 if @hit
      Box.draw @
      COLOR\pop! if @hit

  explode: (world) =>
    AUDIO\play "explode"
    world.particles\add Explosion world, @z, @center!

  -- ensure z is close enough
  on_hit_by: (bullet, world) =>
    return unless bullet.is_bullet
    return unless bullet.alive
    return if @hit
    return if bullet.target and bullet.target != @

    if math.abs(bullet.z - @z) < 0.1
      @explode world
      bullet.alive = false
      @hit = true

  shoot: (world, target) =>
    tx, ty = target\center!
    cx, cy = @center!
    world.entities\add EnemyBullet world, cx, cy, @z

{:Enemy, :EnemyBullet}
