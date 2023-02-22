Class = require 'class'
push = require 'push'

require 'Ball'
require 'Paddle'

-- These are constants, but are not enforced as such by the compiler
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- ball dimensions
BALL_WIDTH = 6
BALL_HEIGHT = 6

-- paddle dimensions
PADDLE_WIDTH = 5
PADDLE_HEIGHT = 25

-- initial ball position
INITIAL_BALL_X = VIRTUAL_WIDTH/2 - BALL_WIDTH/2
INITIAL_BALL_Y = VIRTUAL_HEIGHT/2 - BALL_HEIGHT/2

-- inital paddle positions
INITIAL_PADDLE_LEFT_X = 8
INITIAL_PADDLE_LEFT_Y = 20
INITIAL_PADDLE_RIGHT_X = VIRTUAL_WIDTH - (PADDLE_WIDTH + 8)
INITIAL_PADDLE_RIGHT_Y = VIRTUAL_HEIGHT - (PADDLE_HEIGHT + 20)



-- sets ball and paddle speed (pixels per second)
BALL_SPEED = 100
BALL_SPEED_INCREMENT_RATE = 1.1
MAX_BALL_SPEED = 285 -- this value is roughly equal to 100 * 1.1^11
PADDLE_SPEED = 200

-- sets winning score
WINNING_SCORE = 3

-- Runs only once, upon game start, to initialize the game
function love.load()
    math.randomseed(os.time())

    --[[ 
        When minimizing/maximizing graphics, the default scaling mechanism is bilinear. However,
        this causes blurriness when magnifying 2d graphics (as does trilinear and anisotropic
        filtering), so we use point (otherwise known as nearest) scaling instead. This seeks to
        literally match the blocky pixels of the original smaller image.
    ]]
    love.graphics.setDefaultFilter('nearest', 'nearest')

    smallFont = love.graphics.newFont('04B_03__.TTF', 8)
    scoreFont = love.graphics.newFont('04B_03__.TTF', 32)
    victoryFont = love.graphics.newFont('04B_03__.TTF', 24)

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    love.window.setTitle('Pong')

    sounds = {
        ['start'] = love.audio.newSource('start.wav', 'static'),
        ['wall_bounce'] = love.audio.newSource('wall_bounce.wav', 'static'),
        ['paddle_bounce'] = love.audio.newSource('paddle_bounce.wav', 'static'),
        ['score'] = love.audio.newSource('score.wav', 'static'),
        ['win'] = love.audio.newSource('win.wav', 'static')
    }

    -- Initialize ball and paddles
    ball = Ball(INITIAL_BALL_X, INITIAL_BALL_Y, BALL_WIDTH, BALL_HEIGHT)
    paddle_left = Paddle(INITIAL_PADDLE_LEFT_X, INITIAL_PADDLE_LEFT_Y,
        PADDLE_WIDTH, PADDLE_HEIGHT)
    paddle_right = Paddle(INITIAL_PADDLE_RIGHT_X, INITIAL_PADDLE_RIGHT_Y,
        PADDLE_WIDTH, PADDLE_HEIGHT)

    -- randomly determine which player serves first and move ball accordingly
    -- Player 1 is left paddle, Player 2 is right paddle
    serving_player = math.random(2) == 1 and 1 or 2
    if serving_player==1 then
        ball.dx = BALL_SPEED
    else
        ball.dx = -BALL_SPEED
    end

    -- initialize scores to zero
    paddle_left_score = 0
    paddle_right_score = 0

    -- 1 if first serve of game, 0 otherwise
    game_start = 1

    -- 1 if paddle_left wins, 2 if paddle_right wins
    winning_player = 0

    gameState = 'start'
end

-- Dynamically resizes the window using push
function love.resize(width, height)
    push:resize(width, height)
end

--[[
    Variable 'dt' is short for delta time, and refers to the amount of real time that has elapsed
    regardless of frame rate. So with PADDLE_SPEED = 200 pixels per second, if the computer only
    runs at 1 frame per second, then dt will equal 1, and the paddle will jump 200 pixels
    each frame. If the paddle speed was set only to the frame rate, the game would run horribly
    slowly at 1 fps. By multiplying paddle speed by dt, the game is merely laggy instead (note
    that 1 fps is terrible in either case but this is easily the better option).
]]
function love.update(dt)
    if gameState=='start' then
        paddle_left_score = 0
        paddle_right_score = 0
    elseif gameState=='serve' then
        if game_start==1 then
            sounds['start']:play()
            game_start = 0
        end
    elseif gameState=='play' then
        ball:update(dt)
        paddle_left:update(dt)
        paddle_right:update(dt)

        -- 'w' can override 's' but not the other way around due to the order of the if statements
        if love.keyboard.isDown('w') then
            paddle_left.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('s') then
            paddle_left.dy = PADDLE_SPEED
        else
            paddle_left.dy = 0
        end

        -- 'up' can override 'down' but not the other way around due to the order of the if statements
        if love.keyboard.isDown('up') then
            paddle_right.dy = -PADDLE_SPEED
        elseif love.keyboard.isDown('down') then
            paddle_right.dy = PADDLE_SPEED
        else
            paddle_right.dy = 0
        end

        -- Check for scoring
        if ball.x <= 0 then
            paddle_right_score = paddle_right_score+1
            serving_player = 1
            resetAll()
            if paddle_right_score < WINNING_SCORE then
                sounds['score']:play()
                gameState = 'serve'
            else
                winning_player = 2
                sounds['win']:play()
                gameState = 'win'
            end
        end
        if ball.x >= VIRTUAL_WIDTH-BALL_WIDTH then
            paddle_left_score = paddle_left_score+1
            serving_player = 2
            resetAll()
            if paddle_left_score < WINNING_SCORE then
                sounds['score']:play()
                gameState = 'serve'
            else
                winning_player = 1
                sounds['win']:play()
                gameState = 'win'
            end
        end

        --[[
            Check for collisions.
            Currently there is an issue with the ball colliding with the paddles,
            as the ball's position does not reset and merely reverses 'dx' instead.
            This clearly doesn't work if the ball hits the paddle from the top or
            the bottom.
        ]]
        if ball:collide(paddle_left) then
            sounds['paddle_bounce']:play()
            if ball.dx <= -MAX_BALL_SPEED then
                ball.dx = -ball.dx
            else
                ball.dx = -ball.dx * BALL_SPEED_INCREMENT_RATE
                ball.dy = ball.dy * BALL_SPEED_INCREMENT_RATE
            end
            ball.x = paddle_left.x + paddle_left.width
        end
        if ball:collide(paddle_right) then
            sounds['paddle_bounce']:play()
            if ball.dx >= MAX_BALL_SPEED then
                ball.dx = -ball.dx
            else
                ball.dx = -ball.dx * BALL_SPEED_INCREMENT_RATE
                ball.dy = ball.dy * BALL_SPEED_INCREMENT_RATE
            end
            ball.x = paddle_right.x - ball.width
        end
        if ball.y <= 0 then
            sounds['wall_bounce']:play()
            ball.dy = -ball.dy
            ball.y = 0
        end
        if ball.y >= VIRTUAL_HEIGHT - BALL_HEIGHT then
            sounds['wall_bounce']:play()
            ball.dy = -ball.dy
            ball.y = VIRTUAL_HEIGHT - 6
        end
    end
end

function love.keypressed(key)
    if key=='escape' then
        love.event.quit()
    elseif key=='enter' or key=='return' then
        if gameState=='start' then
            gameState = 'serve'
        elseif gameState=='serve' then
            gameState = 'play'
        elseif gameState=='win' then
            gameState = 'start'
            game_start = 1
        end
    end
end

function love.draw()
    push:apply('start')

    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    -- Display text based on game state
    love.graphics.setFont(smallFont)
    if gameState=='start' then
        love.graphics.printf("Welcome to Pong!", 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press 'enter' to play", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState=='serve' then
        love.graphics.printf("Player " .. tostring(serving_player) .. "'s turn!",
            0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf("Press 'enter' to serve", 0, 32, VIRTUAL_WIDTH, 'center')
    elseif gameState=='win' then
        love.graphics.setFont(victoryFont)
        love.graphics.printf("Player " .. tostring(winning_player) .. " wins!",
            0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf("Press 'enter' to play again, or 'escape' to quit",
            0, 50, VIRTUAL_WIDTH, 'center')
    end

    -- objects are positioned according to their top-left point
    -- if centering according to height, be sure to account for half of the object's size
    love.graphics.setFont(scoreFont)
    love.graphics.printf(paddle_left_score .. "     " .. paddle_right_score,
        0, VIRTUAL_HEIGHT/3, VIRTUAL_WIDTH, 'center')

    --love.graphics.print(paddle_left_score, VIRTUAL_WIDTH/2 - 50, VIRTUAL_HEIGHT/3)
    --love.graphics.print(paddle_right_score, VIRTUAL_WIDTH/2 + 30, VIRTUAL_HEIGHT/3)

    -- Render ball and paddles
    ball:render()
    paddle_left:render()
    paddle_right:render()

    displayFPS()

    push:apply('end')
end

-- Resets ball and paddles to their initial positions
function resetAll()
    ball:reset()
    paddle_left:reset()
    paddle_right:reset()
end

-- Displays current FPS in green in upper left corner of screen
function displayFPS()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setFont(smallFont)
    --[[
        tostring() is essentially a cast; necessary since getFPS() returns an int
        '..' is used for string concatenation
    ]]
    love.graphics.print('FPS ' .. tostring(love.timer.getFPS()), 40, 20)
    love.graphics.setColor(0, 0, 0, 0)
end