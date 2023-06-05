require 'rubygems'
require 'gosu'

# bullet constants
BULLET_SPEED = 25
BULLET_DAMAGE = 5

class Bullet
    attr_accessor :speed, :damage, :rotation, :color, :image, :x, :y, :width, :height

    def initialize(x, y, rotation, color)
        @speed = BULLET_SPEED
        @damage = BULLET_DAMAGE
        @rotation = rotation
        @color = color
        @image = Gosu::Image.new("media/PNG/Bullets/bullet" + @color + "Silver_outline.png")
        @x = x
        @y = y
        @width = @image.width
        @height = @image.height
    end
end

# move the individual bullet according to the rotation
def move_bullet(bullet)
    radians = Gosu.degrees_to_radians(bullet.rotation - 90)
    bullet.x += Math.cos(radians) * bullet.speed
    bullet.y += Math.sin(radians) * bullet.speed
end
