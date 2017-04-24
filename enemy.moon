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
  has_shield: false
  sprite_frame: 1

  health: 3

  lazy sprite: ->
    Spriter "images/enemy_sprites.png", 16

  new: (world, x, y) =>
    super 0, 0, @w, @h
    @move_center x, y
    @z = 2
    @effects = EffectList @
    @time = 0

  active: =>
    @alive and not @dying

  update: (dt, world) =>
    @time += dt
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
      @draw_sprite_cell @sprite_frame
      @effects\after!

      if @has_shield
        x, y = @center!
        g.setBlendMode "add"

        g.push!
        g.translate @center!

        g.scale 1 + math.abs math.sin @time * 3
        g.rotate @time * 2

        @sprite\draw "0,32,16,32", -16, -16
        @sprite\draw "0,32,16,32", 16, -16, 0, -1, 1

        g.pop!
        g.setBlendMode "alpha"

  explode: (world) =>
    @dying = true
    AUDIO\play "explode"
    @effects\add BlowOutEffect 0.5, -> @dying = false
    world.particles\add Explosion world, @z, @center!

    world.score += 7 * world.score_mult
    world.score_mult += 1

  -- ensure z is close enough
  on_hit_by: (bullet, world) =>
    return unless bullet.is_bullet
    return unless bullet.alive
    return if bullet.target and bullet.target != @
    return unless @active!

    if math.abs(bullet.z - @z) < 0.1
      bullet.alive = false
      if @has_shield
        @has_shield = false
        AUDIO\play "lose_shield"
      else
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


class EnemyShield extends Enemy
  has_shield: true

class EvilEnemy extends Enemy
  health: 6
  sprite_frame: 0
  has_shield: false

class EvilEnemyShield extends Enemy
  health: 6
  sprite_frame: 0
  has_shield: false

{:Enemy, :EnemyBullet, :EnemyShield, :EvilEnemy, :EvilEnemyShield}
