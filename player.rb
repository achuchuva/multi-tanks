require 'rubygems'
require 'gosu'
require './bullet.rb'

# player constants
MAX_HEALTH = 100
MAX_AMMO = 5
PLAYER_SPEED = 5
FIRE_RATE = 1 # measured in seconds

class Player
    attr_accessor :score, :health, :ammo, :tick, :next_tick, :speed, :rotation, :color, :image, :barrel_image, :x, :y, :width, :height

    def initialize(x, y, rotation, color)
        @score = 0
        @health = MAX_HEALTH
        @ammo = MAX_AMMO
        @tick = 0
        @next_tick = FIRE_RATE
        @speed = PLAYER_SPEED
        @rotation = rotation
        @color = color
        @image = Gosu::Image.new("media/PNG/Tanks/tank" + @color + "_outline.png")
        @barrel_image = Gosu::Image.new("media/PNG/Tanks/barrel" + @color + "_outline.png")
        @x = x
        @y = y
        @width = @image.width
        @height = @image.height
    end
end

# move the player forward based on rotation
def move_player_forward(player)
    radians = Gosu.degrees_to_radians(player.rotation + 90)
    player.x += Math.cos(radians) * player.speed
    player.y += Math.sin(radians) * player.speed
end

# move the player backward based on rotation
def move_player_backward(player)
    radians = Gosu.degrees_to_radians(player.rotation + 90)
    player.x -= Math.cos(radians) * player.speed
    player.y -= Math.sin(radians) * player.speed
end

# ensure that the player's position is always within the defined window size
def check_player_bounds(player)
    player.y = [player.y, (HEIGHT - player.height / 2) - 100].min
    player.y = [player.y, player.height / 2].max
    player.x = [player.x, WIDTH - player.width / 2].min
    player.x = [player.x, player.width / 2].max
end

# rotate player left at the player's speed
def rotate_player_left(player)
    player.rotation -= player.speed
    player.rotation = (player.rotation % 360).abs
end

# rotate player right at the player's speed
def rotate_player_right(player)
    player.rotation += player.speed
    player.rotation = (player.rotation % 360).abs
end

# if the player has ammo, create a bullet and sound and decrease ammo by 1
def player_shoot(player, bullets)
    if (player.ammo > 0)
        fire = Gosu::Song.new("media/Sound/fire.mp3")
        fire.play(false)
        bullets.push(Bullet.new(player.x, player.y, player.rotation + 180, player.color))
        player.ammo -= 1
    end
end

# over time, refill ammo but make sure this is done at the constant FIRE_RATE
def replenish_player_bullets(player)
    player.tick = Gosu.milliseconds / 1000
    if player.tick >= player.next_tick
        if player.ammo < MAX_AMMO
            player.ammo += 1
            player.next_tick = (Gosu.milliseconds / 1000) + FIRE_RATE
        end
    end
end

# apply damage to the player
def player_take_damage(player, amount)
    player.health -= amount
    if player.health <= 0
        player.health = 0
    end
end
