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
  damage: 1

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

  health: 3

  lazy sprite: ->
    Spriter "images/enemy_sprites.png", 16

  new: (world, x, y) =>
    super 0, 0, @w, @h
    @move_center x, y
    @z = 2
    @effects = EffectList @

  active: =>
    @alive and not @dying

  update: (dt, world) =>
    -- @z -= dt * world.space.scroll_speed / 3
    @seq\update dt if @seq
    @effects\update dt
    @dying or (@z > -1 and @health > 0)

  draw_sprite_cell: (frame) =>
    sw = @sprite.cell_w
    sh = @sprite.cell_h / 2

    g.push!
    g.translate @center!

    @sprite\draw frame, -sw, -sh
    @sprite\draw frame, sw, -sh, 0, -1, 1
    g.pop!

  draw: (world) =>
    world.space\draw_at_z @z, ->
      @effects\before!
      @draw_sprite_cell 1
      @effects\after!

  explode: (world) =>
    @dying = true
    AUDIO\play "explode"
    @effects\add BlowOutEffect 0.5, -> @dying = false
    world.particles\add Explosion world, @z, @center!

    world.score += 77 * world.score_mult
    world.score_mult += 1

  -- ensure z is close enough
  on_hit_by: (bullet, world) =>
    return unless bullet.is_bullet
    return unless bullet.alive
    return if bullet.target and bullet.target != @
    return unless @active!

    if math.abs(bullet.z - @z) < 0.1
      bullet.alive = false
      @health -= (bullet.damage or 1)

      if @health <= 0
        @explode world
      else
        AUDIO\play "enemy_hit"
        @effects\add FlashEffect!
        @effects\add ShakeEffect!

  shoot: (world, target) =>
    return unless @alive
    return if target.dying or target.dead

    tx, ty = target\center!
    cx, cy = @center!
    world.entities\add EnemyBullet world, cx, cy, @z

{:Enemy, :EnemyBullet}
