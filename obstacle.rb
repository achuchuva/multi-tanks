require 'rubygems'
require 'gosu'

class Obstacle
    attr_accessor :color, :image, :x, :y, :width, :height

    def initialize(x, y, color)
        @color = color
        @image = Gosu::Image.new("media/PNG/Obstacles/barrel" + @color + "_side.png")
        @x = x
        @y = y
        @width = @image.width
        @height = @image.height
    end
end
