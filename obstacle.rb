require 'rubygems'
require 'gosu'

class Obstacle
    attr_accessor :color, :image, :x, :y, :rotation, :width, :height

    def initialize(x, y, rotation, color)
        @color = color
        @image = Gosu::Image.new("media/PNG/Obstacles/barrel" + @color + "_side.png")
        @x = x
        @y = y
        @rotation = rotation
        @width = @image.width
        @height = @image.height
    end
end
