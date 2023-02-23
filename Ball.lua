Ball = Class{}

function Ball:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    -- equivalent to "(math.random(2)==1) ? -100 : 100" in C
    self.dx = math.random(2)==1 and -BALL_SPEED or BALL_SPEED
    self.dy = math.random(2)==1 and
        math.random(-BALL_SPEED-10, -BALL_SPEED+10) or math.random(BALL_SPEED+10, BALL_SPEED-10)
end

function Ball:collide(box)
    if self.x >= (box.x + box.width) or (self.x + self.width) <= box.x then
        return false
    end
    if self.y >= (box.y + box.height) or (self.y + self.height) <= box.y then
        return false
    end
    return true
end

-- return ball position and speed to default values
function Ball:reset()
    self.x = INITIAL_BALL_X
    self.y = INITIAL_BALL_Y
    self.dx = serving_player==1 and BALL_SPEED or -BALL_SPEED
    self.dy = math.random(2)==1 and
        math.random(-BALL_SPEED-10, -BALL_SPEED+10) or math.random(BALL_SPEED+10, BALL_SPEED-10)
end

function Ball:update(dt)
    self.x = self.x + self.dx*dt
    self.y = self.y + self.dy*dt
end

function Ball:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end