require 'rubygems'
require 'gosu'

class Explosion
    attr_accessor :image, :index, :finished, :x, :y

    def initialize(x, y)
        @x = x
        @y = y
        
        @image = Gosu::Image.load_tiles("media/PNG/Smoke/explosion.png", 32, 32)
        @index = 0
        @finished = false
    end
end

def draw_explosion explosion
    current_img = explosion.image[Gosu.milliseconds / 120 % 3]
    current_img.draw(explosion.x, explosion.y, ZOrder::UI, 1.0, 1.0)

    if current_img == explosion.image[2]
        explosion.finished = true
    end
end