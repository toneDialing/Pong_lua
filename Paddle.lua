Paddle = Class{}

-- initiates a Paddle with starting position (x, y) and starting dimensions (width X height)
function Paddle:init(x, y, width, height)
    self.initial_x = x
    self.initial_y = y
    self.x = x
    self.y = y
    self.width = width
    self.height = height

    self.dy = 0
end

function Paddle:reset()
    self.x = self.initial_x
    self.y = self.initial_y
end

function Paddle:update(dt)
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy*dt)
    elseif self.dy > 0 then
        self.y = math.min(VIRTUAL_HEIGHT - PADDLE_HEIGHT, self.y + self.dy*dt)
    end
end

function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end