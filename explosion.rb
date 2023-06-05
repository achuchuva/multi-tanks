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

# draw the explosion frame by frame
def draw_explosion explosion
    # the image property is an array of the sliced images
    current_img = explosion.image[Gosu.milliseconds / 120 % explosion.image.length]
    current_img.draw(explosion.x, explosion.y, ZOrder::UI, 1.0, 1.0)

    if current_img == explosion.image[explosion.image.length - 1]
        explosion.finished = true
    end
end

# if the explosion has finished set to true, remove it
def remove_explosions
    @explosions.reject! do |explosion|
        if explosion.finished
            true
        else
            false
        end
    end
end
