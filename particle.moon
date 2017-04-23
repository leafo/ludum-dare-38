{graphics: g} = love

class ZParticle extends Particle
  new: (world, @z, x, y)=>
    @dz = -world.space.scroll_speed + (random_normal! - 0.5)
    super x, y,
      Vec2d(0, 1)\random_heading(60) * -rand(200, 300),
      Vec2d(0, 800)

  update: (dt, ...) =>
    @z += @dz * dt
    super dt, ...

  draw: (world) =>
    world.space\draw_at_z @z, ->
      g.setPointSize 3
      g.points @x, @y


class ZImageParticle extends ImageParticle
  new: (world, @z, ...) =>
    @dz = -world.space.scroll_speed + (random_normal! - 0.5)
    super ...
    @w = @sprite\width!
    @h = @sprite\height!

  update: (dt, ...) =>
    @z += @dz * dt
    super dt, ...

  draw: (world) =>
    world.space\draw_at_z @z, ->
      super!

class Spark extends ZImageParticle
  ad_left: 0.05
  lazy sprites: -> {
    imgfy "images/spark.png"
    imgfy "images/spark2.png"
  }

  new: (...) =>
    @sprite = pick_one unpack @sprites
    super ...

    @vel = Vec2d(0, 1)\random_heading(60) * -rand(200, 300)
    @accel = Vec2d(0, 800)

    @dscale = rand 0.6, 1.1
    @dspin = rand -4, 4


class Smoke extends ZImageParticle
  life: 0.5

  lazy sprites: -> {
    imgfy "images/smoke.png"
    imgfy "images/smoke_2.png"
  }

  new: (...) =>
    @sprite = pick_one unpack @sprites
    super ...

    @vel = Vec2d(0, 1)\random_heading(180) * -rand(20, 40)
    @accel = Vec2d(0, 100)

    @dscale = rand 0.6, 1.4
    @dspin = rand -1, 1

class Explosion extends Emitter
  duration: 0.1
  count: 20

  new: (world, @z, x, y) =>
    super world, x, y

  make_particle: (x, y) =>
    cls = pick_one(
      Spark
      Smoke
      ZParticle
    )

    cls @world, @z, x, y


{:Explosion, :Spark, :Smoke, :ZImageParticle, ZParticle}
