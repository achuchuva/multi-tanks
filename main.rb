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

# different game states
module GameState
    INITIALIZED, PLAYING, GAME_OVER = *0..2
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
        @game_state = GameState::INITIALIZED
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
        if @game_state != GameState::PLAYING
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

        # remove explosions over time
        remove_explosions()

        # handle game over
        handle_game_over()
    end

    # function for checking collision with all obstacles at once, used for bullets
    def collides_with_obstacle(object, obstacles)
        obstacles.each do |obstacle|
            if collides_with?(object, obstacle)
                return obstacle
            end
        end

        return nil
    end

    # determines whether the two objects overlap
    def collides_with?(object1, object2)
        # calculate the half-width and half-height of each rectangle
        half_width = (object1.width / 2.0) + (object2.width / 2.0)
        half_height = (object1.height / 2.0) + (object2.height / 2.0)
    
        # calculate the distance between the centers of the two rectangles
        distance_x = (object1.x - object2.x).abs
        distance_y = (object1.y - object2.y).abs
    
        # check for collision by comparing the distance with the half-width and half-height
        if distance_x < half_width && distance_y < half_height
            return true
        else
            return false
        end
    end

    # actually apply changes to objects position based on overlap
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

    # render the player and the gun barrel
    def draw_player(player)
        if player.health > 0
            player.image.draw_rot(player.x, player.y, ZOrder::PLAYER, player.rotation)
            # extra calculations are needed to ensure the barrel is at the correct position
            radians = Gosu.degrees_to_radians(player.rotation + 90)
            barrelX = 25 * Math.cos(radians)
            barrelY = 25 * Math.sin(radians)
            player.barrel_image.draw_rot(player.x + barrelX, player.y + barrelY, ZOrder::PLAYER, player.rotation)
        end
    end

    # loop through and draw bullets
    def draw_bullets(bullets)
        bullets.each do |bullet|
            bullet.image.draw_rot(bullet.x, bullet.y, ZOrder::PLAYER, bullet.rotation)
        end
    end

    # loop through and draw obstacles
    def draw_environment(obstacles)
        obstacles.each do |obstacle|
            obstacle.image.draw_rot(obstacle.x, obstacle.y, ZOrder::PLAYER, obstacle.rotation)
        end
    end

    # draw the UI seen during gameplay
    def draw_ui
        Gosu.draw_rect(0, HEIGHT - 100, WIDTH, 100, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
        draw_player_ui(@player_a, 0, "Player 1")
        draw_player_ui(@player_b, WIDTH / 2, "Player 2")
    end

    # draw the actual player properties like score, health and ammo
    def draw_player_ui(player, left_x, player_name)
        @large_font.draw_text(player_name, left_x + 10, HEIGHT - 80, ZOrder::UI, 1, 1, Gosu::Color::RED)
        @font.draw_text("Score: " + player.score.to_s, left_x + 20, HEIGHT - 40, ZOrder::UI, 1, 1, Gosu::Color::BLACK)
        @font.draw_text("Health", left_x + 170, HEIGHT - 50, ZOrder::UI, 1, 1, Gosu::Color::BLACK)
        @font.draw_text("Ammo", left_x + 170, HEIGHT - 80, ZOrder::UI, 1, 1, Gosu::Color::BLACK)
        draw_bar(left_x + 240, HEIGHT - 50, player.health, MAX_HEALTH, 100, Gosu::Color::GREEN)
        draw_bar(left_x + 240, HEIGHT - 80, player.ammo, MAX_AMMO, 100, Gosu::Color.new(255, 165, 0))
    end

    # draw a bar that can be filled depending on the passed value
    def draw_bar(x, y, value, max, width, color)
        bar_width = (value.to_f / max.to_f) * width.to_f
        bg = Gosu::Color::GRAY

        # render the background bar
        draw_quad(x, y, bg, x + width, y, bg, x + width, y + 20, bg, x, y + 20, bg, ZOrder::UI, :default)
    
        # render the filled portion of the bar
        draw_quad(x, y, color, x + bar_width, y, color, x + bar_width, y + 20, color, x, y + 20, color, ZOrder::UI, :default)
    end

    # if the game state is not playing, an end screen will be drawn
    def draw_end_screens()
        if @game_state == GameState::INITIALIZED 
            draw_rect(290, 240, 420, 320, Gosu::Color::BLACK, ZOrder::UI, :default)
            draw_rect(300, 250, 400, 300, Gosu::Color::WHITE, ZOrder::UI, :default)
            draw_startup()
        elsif @game_state == GameState::GAME_OVER
            draw_rect(290, 240, 420, 320, Gosu::Color::BLACK, ZOrder::UI, :default)
            draw_rect(300, 250, 400, 300, Gosu::Color::WHITE, ZOrder::UI, :default)
            draw_game_over()
        end
    end

    # draw UI for the game startup
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

    # draw UI for the game over screen
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
        # if the game is playing, handle shooting for each player
        if @game_state == GameState::PLAYING
            if id == Gosu::KbSpace
                player_shoot(@player_a, @bullets_a)
            end

            if id == Gosu::KbReturn
                player_shoot(@player_b, @bullets_b)
            end
        end

        # if the game is not playing, handle mouse clicks that appear as button clicks
        if id == Gosu::MsLeft
            if @game_state == GameState::INITIALIZED && mouse_over_quad(450, 480, 550, 530)
                @game_state = GameState::PLAYING
            elsif @game_state == GameState::GAME_OVER && mouse_over_quad(400, 480, 600, 530)
                @game_state = GameState::PLAYING
                start_game()
            end
        end
    end

    # determine if the mouse is over specified coordinates
    def mouse_over_quad(x1, y1, x2, y2)
        if ((mouse_x > x1 && mouse_x < x2) && (mouse_y > y1 && mouse_y < y2))
            true
          else
            false
        end
    end

    # move bullets
    def move_bullets(bullets)
        bullets.each do |bullet|
            move_bullet(bullet)
        end
    end

    # remove bullets based on collision
    def remove_bullets
        @bullets_a.reject! do |bullet|
            if bullet.y > HEIGHT || bullet.y < 0 || bullet.x > WIDTH || bullet.x < 0
                # the bullet is offscreen
                true
            elsif collides_with_obstacle(bullet, @obstacles)
                # the bullet collides with obstacle
                @explosions.push(Explosion.new(bullet.x, bullet.y))
                hit = Gosu::Song.new("media/Sound/hit.wav")
                hit.play(false)
                true
            elsif collides_with?(bullet, @player_b)
                # the bullet collided with player b
                player_take_damage(@player_b, bullet.damage)
                @explosions.push(Explosion.new(bullet.x, bullet.y))
                hit = Gosu::Song.new("media/Sound/hit.wav")
                hit.play(false)
                @player_a.score += (100 - Gosu.distance(bullet.x, bullet.y, @player_b.x, @player_b.y)).to_i
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
                hit = Gosu::Song.new("media/Sound/hit.wav")
                hit.play(false)
                true
            elsif collides_with?(bullet, @player_a)
                # the bullet collided with player a
                player_take_damage(@player_a, bullet.damage)
                @explosions.push(Explosion.new(bullet.x, bullet.y))
                hit = Gosu::Song.new("media/Sound/hit.wav")
                hit.play(false)
                @player_b.score += (100 - Gosu.distance(bullet.x, bullet.y, @player_a.x, @player_a.y)).to_i
                true
            else
                false
            end
        end
    end

    # change state to game over and determine a winner
    def handle_game_over()
        if @player_a.health <= 0
            @game_state = GameState::GAME_OVER
            @winner = @player_b
        end

        if @player_b.health <= 0
            @game_state = GameState::GAME_OVER
            @winner = @player_a
        end
    end
end

window = Game.new
window.show
