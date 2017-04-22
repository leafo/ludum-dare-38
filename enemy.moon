{graphics: g} = love

class ZParticle extends Particle
  new: (world, @z, ...)=>
    @dz = -world.space.scroll_speed + (random_normal! - 0.5)
    super ...

  update: (dt, ...) =>
    @z += @dz * dt
    super dt, ...

  draw: (world) =>
    world.space\draw_at_z @z, ->
      g.setPointSize 3
      g.points @x, @y

class Spark extends ImageParticle
  ad_left: 0.05
  lazy sprite: -> imgfy "images/spark.png"

  new: (world, @z, x, y) =>
    @dz = -world.space.scroll_speed + (random_normal! - 0.5)
    super x, y,
      Vec2d(0, 1)\random_heading(60) * -rand(200, 300),
      Vec2d(0, 800)

    @dscale = rand 0.6, 1.1
    @dspin = rand -4, 4

  update: (dt, ...) =>
    @z += @dz * dt
    super dt, ...

  draw: (world) =>
    world.space\draw_at_z @z, ->
      super!

class Smoke extends ImageParticle
  lazy sprite: -> imgfy "images/spark.png"


class Explosion extends Emitter
  duration: 0.2

  new: (world, @z, x, y) =>
    super world, x, y

  make_particle: (x, y) =>
    Spark @world, @z, x, y

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
    @z -= dt
    true

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
