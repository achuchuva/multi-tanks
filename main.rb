
require 'rubygems'
require 'gosu'

require './player.rb'
require './bullet.rb'
require './obstacle.rb'
require './explosion.rb'

# order of elements
module ZOrder
    BACKGROUND, PLAYER, UI = *0..2
end

# window constants
WIDTH = 1000
HEIGHT = 800

class Game < Gosu::Window

    # initialize the game
    def initialize
        super WIDTH, HEIGHT, false
        self.caption = "Multi Tanks"
        @font = Gosu::Font.new(20)
        @large_font = Gosu::Font.new(40)
        @background = Gosu::Image.new("media/PNG/Environment/bg.png")

        # initialize some global variables
        @started = false
        @game_over = false
        @winner = nil

        start_game()
    end

    def start_game()
        # intialize the players
        @player_a = Player.new(50, HEIGHT - 150, 270, "Red")
        @player_b = Player.new(WIDTH - 50, 50, 90, "Blue")

        # initialize each players bullets
        @bullets_a = Array.new()
        @bullets_b = Array.new()

        # generate the environment with obstacles
        @obstacles = Array.new()
        @obstacles.push(Obstacle.new(200, HEIGHT - 220, 0, "Green"))
        @obstacles.push(Obstacle.new(200, HEIGHT - 290, 0, "Grey"))
        @obstacles.push(Obstacle.new(200, HEIGHT - 360, 0, "Green"))
        @obstacles.push(Obstacle.new(200, HEIGHT - 430, 0, "Green"))
        @obstacles.push(Obstacle.new(210, HEIGHT - 500, 90, "Green"))
        @obstacles.push(Obstacle.new(280, HEIGHT - 500, 90, "Grey"))
        @obstacles.push(Obstacle.new(350, HEIGHT - 500, 90, "Grey"))
        @obstacles.push(Obstacle.new(420, HEIGHT - 500, 90, "Grey"))


        @obstacles.push(Obstacle.new(600, HEIGHT - 400, 0, "Green"))
        @obstacles.push(Obstacle.new(600, HEIGHT - 470, 0, "Grey"))
        @obstacles.push(Obstacle.new(600, HEIGHT - 680, 0, "Green"))
        @obstacles.push(Obstacle.new(600, HEIGHT - 610, 0, "Grey"))
        @obstacles.push(Obstacle.new(610, HEIGHT - 540, 90, "Grey"))
        @obstacles.push(Obstacle.new(680, HEIGHT - 540, 90, "Green"))
        @obstacles.push(Obstacle.new(750, HEIGHT - 540, 90, "Green"))
        @obstacles.push(Obstacle.new(820, HEIGHT - 540, 90, "Grey"))

        # initialize explosion array
        @explosions = Array.new()
    end

    # update method that is called repeatedly per second
    def update
        # don't allow movement if the game hasn't started or is over
        if !@started || @game_over
            return nil
        end

        # move player a
        if button_down?(Gosu::KbS)
            move_player_backward(@player_a)
        end
        
        if button_down?(Gosu::KbW)
            move_player_forward(@player_a)
        end

        if button_down?(Gosu::KbD)
            rotate_player_right(@player_a)
        end
        
        if button_down?(Gosu::KbA)
            rotate_player_left(@player_a)
        end

        # check player a bounds
        check_player_bounds(@player_a)

        # move player b
        if button_down?(Gosu::KbDown)
            move_player_backward(@player_b)
        end
        
        if button_down?(Gosu::KbUp)
            move_player_forward(@player_b)
        end

        if button_down?(Gosu::KbRight)
            rotate_player_right(@player_b)
        end
        
        if button_down?(Gosu::KbLeft)
            rotate_player_left(@player_b)
        end

        # check player b bounds
        check_player_bounds(@player_b)

        # player collisions
        if collides_with?(@player_a, @player_b)
            resolve_collision(@player_a, @player_b, true)
        end

        # player a collision with obstacles
        @obstacles.each do |obstacle|
            if collides_with?(@player_a, obstacle)
                resolve_collision(@player_a, obstacle, false)
            end
        end

        # player b collision with obstacles
        @obstacles.each do |obstacle|
            if collides_with?(@player_b, obstacle)
                resolve_collision(@player_b, obstacle, false)
            end
        end

        # replenish bullets
        replenish_player_bullets(@player_a)
        replenish_player_bullets(@player_b)

        # move bullets
        move_bullets(@bullets_a)
        move_bullets(@bullets_b)

        # remove bullets based on their collision
        remove_bullets()

        remove_explosions()

        # handle game over
        handle_game_over()
    end

    def collides_with_obstacle(object, obstacles)
        obstacles.each do |obstacle|
            if collides_with?(object, obstacle)
                return obstacle
            end
        end

        return nil
    end

    def collides_with?(object1, object2)
        # calculate the half-width and half-height of each rectangle
        half_width = (object1.width / 2.0) + (object2.width / 2.0)
        half_height = (object1.height / 2.0) + (object2.height / 2.0)
    
        # calculate the center positions of each rectangle
        self_center_x = object1.x
        self_center_y = object1.y
        other_center_x = object2.x
        other_center_y = object2.y
    
        # calculate the distance between the centers of the two rectangles
        distance_x = (self_center_x - other_center_x).abs
        distance_y = (self_center_y - other_center_y).abs
    
        # check for collision by comparing the distance with the half-width and half-height
        if distance_x < half_width && distance_y < half_height
          return true
        else
          return false
        end
      end

    def resolve_collision(object1, object2, can_be_pushed)
        # calculate the overlap in the x-axis and y-axis
        overlap_x = (object1.width + object2.width) / 2.0 - (object2.x - object1.x).abs
        overlap_y = (object1.height + object2.height) / 2.0 - (object2.y - object1.y).abs
    
        if overlap_x < overlap_y
            # resolve collision horizontally
            if object1.x < object2.x
                # offset the object/s
                object1.x -= overlap_x
                if can_be_pushed
                    object2.x += overlap_x
                end
            else
                # offset the object/s
                object1.x += overlap_x
                if can_be_pushed
                    object2.x -= overlap_x
                end
            end
        else
            # resolve collision vertically
            if object1.y < object2.y
                # offset the object/s
                object1.y -= overlap_y
                if can_be_pushed
                    object2.y += overlap_y
                end
            else
                # offset the object/s
                object1.y += overlap_y
                if can_be_pushed
                    object2.y -= overlap_y
                end
            end
        end
    end

    # draw or redraw the window
    def draw
        # draw bg
        @background.draw(0, 0, ZOrder::BACKGROUND, 1, 1, Gosu::Color::WHITE, :default)

        # draw both players
        draw_player(@player_a)
        draw_player(@player_b)

        # draw bullets
        draw_bullets(@bullets_a)
        draw_bullets(@bullets_b)

        # draw environment
        draw_environment(@obstacles)

        # draw explosions
        @explosions.each do |explosion|
            draw_explosion(explosion)
        end

        # draw ui
        draw_ui()

        # draw end screen
        draw_end_screens()
    end

    def draw_player(player)
        if player.health > 0
            player.image.draw_rot(player.x, player.y, ZOrder::PLAYER, player.rotation)
            radians = Gosu.degrees_to_radians(player.rotation + 90)
            barrelX = 25 * Math.cos(radians)
            barrelY = 25 * Math.sin(radians)
            player.barrel_image.draw_rot(player.x + barrelX, player.y + barrelY, ZOrder::PLAYER, player.rotation)
        end
    end

    def draw_bullets(bullets)
        bullets.each do |bullet|
            bullet.image.draw_rot(bullet.x, bullet.y, ZOrder::PLAYER, bullet.rotation)
        end
    end

    def draw_environment(obstacles)
        obstacles.each do |obstacle|
            obstacle.image.draw_rot(obstacle.x, obstacle.y, ZOrder::PLAYER, obstacle.rotation)
        end
    end

    def draw_ui
        Gosu.draw_rect(0, HEIGHT - 100, WIDTH, 100, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
        draw_player_ui(@player_a, 0, "Player 1")
        draw_player_ui(@player_b, WIDTH / 2, "Player 2")
    end

    def draw_player_ui(player, left_x, player_name)
        @large_font.draw_text(player_name, left_x + 10, HEIGHT - 80, ZOrder::UI, 1, 1, Gosu::Color::RED)
        @font.draw_text("Score: " + player.score.to_s, left_x + 20, HEIGHT - 40, ZOrder::UI, 1, 1, Gosu::Color::BLACK)
        @font.draw_text("Health", left_x + 170, HEIGHT - 50, ZOrder::UI, 1, 1, Gosu::Color::BLACK)
        @font.draw_text("Ammo", left_x + 170, HEIGHT - 80, ZOrder::UI, 1, 1, Gosu::Color::BLACK)
        draw_bar(left_x + 240, HEIGHT - 50, player.health, MAX_HEALTH, 100, Gosu::Color::GREEN)
        draw_bar(left_x + 240, HEIGHT - 80, player.ammo, MAX_AMMO, 100, Gosu::Color.new(255, 165, 0))
    end

    def draw_bar(x, y, value, max, width, color)
        bar_width = (value.to_f / max.to_f) * width.to_f
        bg = Gosu::Color::GRAY

        # Render the background bar
        draw_quad(x, y, bg, x + width, y, bg, x + width, y + 20, bg, x, y + 20, bg, ZOrder::UI, :default)
    
        # Render the filled portion of the bar
        draw_quad(x, y, color, x + bar_width, y, color, x + bar_width, y + 20, color, x, y + 20, color, ZOrder::UI, :default)
    end

    def draw_end_screens()
        if !@started
            draw_rect(290, 240, 420, 320, Gosu::Color::BLACK, ZOrder::UI, :default)
            draw_rect(300, 250, 400, 300, Gosu::Color::WHITE, ZOrder::UI, :default)
            draw_startup()
        elsif @game_over
            draw_rect(290, 240, 420, 320, Gosu::Color::BLACK, ZOrder::UI, :default)
            draw_rect(300, 250, 400, 300, Gosu::Color::WHITE, ZOrder::UI, :default)
            draw_game_over()
        end
    end

    def draw_startup()
        @large_font.draw_text("MULTI-TANKS", 390, 260, ZOrder::UI, 1, 1, Gosu::Color::RED)
        @font.draw_text("Two player tank game", 310, 330, ZOrder::UI, 1, 1, Gosu::Color::BLACK)
        @font.draw_text("Player 1: W/S to move, A/D to rotate", 310, 360, ZOrder::UI, 1, 1, Gosu::Color.new(232, 106, 23))
        @font.draw_text("Space to shoot", 310, 390, ZOrder::UI, 1, 1, Gosu::Color.new(232, 106, 23))
        @font.draw_text("Player 2: Up/Down to move, Left/Right to rotate", 310, 430, ZOrder::UI, 1, 1, Gosu::Color.new(30, 167, 225))
        @font.draw_text("Enter to shoot", 310, 460, ZOrder::UI, 1, 1, Gosu::Color.new(30, 167, 225))
        Gosu.draw_rect(450, 480, 100, 50, Gosu::Color::GREEN, ZOrder::UI, mode=:default)
        @font.draw_text("BATTLE", 465, 495, ZOrder::UI, 1, 1, Gosu::Color::WHITE)
    end

    def draw_game_over()
        text = @winner == @player_a ? "PLAYER 1 WINS!" : "PLAYER 2 WINS!"
        @large_font.draw_text(text, 360, 300, ZOrder::UI, 1, 1, Gosu::Color::RED)
        @font.draw_text("Player 1 score: " + @player_a.score.to_s, 340, 370, ZOrder::UI, 1, 1, Gosu::Color.new(232, 106, 23))
        @font.draw_text("Player 2 score: " + @player_b.score.to_s, 340, 420, ZOrder::UI, 1, 1, Gosu::Color.new(30, 167, 255))
        Gosu.draw_rect(400, 480, 200, 50, Gosu::Color::GREEN, ZOrder::UI, mode=:default)
        @font.draw_text("PLAY AGAIN", 450, 495, ZOrder::UI, 1, 1, Gosu::Color::WHITE)
    end

    # handle the button presses
    def button_down(id)
        if @started && !@game_over
            if id == Gosu::KbSpace
                player_shoot(@player_a, @bullets_a)
            end

            if id == Gosu::KbReturn
                player_shoot(@player_b, @bullets_b)
            end
        end

        if id == Gosu::MsLeft
            if !@started && mouse_over_quad(450, 480, 550, 530)
                @started = true
            elsif @game_over && mouse_over_quad(400, 480, 600, 530)
                @game_over = false
                start_game()
            end
        end
    end

    def mouse_over_quad(x1, y1, x2, y2)
        if ((mouse_x > x1 && mouse_x < x2) && (mouse_y > y1 && mouse_y < y2))
            true
          else
            false
        end
    end

    def move_bullets(bullets)
        bullets.each do |bullet|
            move_bullet(bullet)
        end
    end

    def remove_bullets
        @bullets_a.reject! do |bullet|
            if bullet.y > HEIGHT || bullet.y < 0 || bullet.x > WIDTH || bullet.x < 0
                # the bullet is offscreen
                true
            elsif collides_with_obstacle(bullet, @obstacles)
                # the bullet collides with obstacle
                @explosions.push(Explosion.new(bullet.x, bullet.y))
                true
            elsif Gosu.distance(bullet.x, bullet.y, @player_b.x, @player_b.y) < 50
                # the bullet collided with player b
                player_take_damage(@player_b, bullet.damage)
                @explosions.push(Explosion.new(bullet.x, bullet.y))
                @player_a.score += (50 - Gosu.distance(bullet.x, bullet.y, @player_b.x, @player_b.y)).to_i
                true
            else
                false
            end
        end

        @bullets_b.reject! do |bullet|
            if bullet.y > HEIGHT || bullet.y < 0 || bullet.x > WIDTH || bullet.x < 0
                # the bullet is offscreen
                true
            elsif collides_with_obstacle(bullet, @obstacles)
                # the bullet collides with obstacle
                @explosions.push(Explosion.new(bullet.x, bullet.y))
                true
            elsif Gosu.distance(bullet.x, bullet.y, @player_a.x, @player_a.y) < 50
                # the bullet collided with player a
                player_take_damage(@player_a, bullet.damage)
                @explosions.push(Explosion.new(bullet.x, bullet.y))
                @player_b.score += (50 - Gosu.distance(bullet.x, bullet.y, @player_a.x, @player_a.y)).to_i
                true
            else
                false
            end
        end
    end

    def remove_explosions
        @explosions.reject! do |explosion|
            if explosion.finished
                true
            else
                false
            end
        end
    end

    def handle_game_over()
        if @player_a.health <= 0
            @game_over = true
            @winner = @player_b
        end

        if @player_b.health <= 0
            @game_over = true
            @winner = @player_a
        end
    end
end

window = Game.new
window.show
