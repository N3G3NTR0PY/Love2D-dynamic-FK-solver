----- COLORS
local color = {
    black = {0, 0, 0, 1},
    white = {1, 1, 1, 1},
    gray  = {0.5, 0.5, 0.5, 1}
}

----- WINDOW DEFAULTS
local window = {
	fullscreen = false,
    width = 800, 
    height = 600,
    title = 'Forward Kinematics Solver',
    color = color.black
}
local centerX, centerY = window.width / 2, window.height / 2

----- CONFIG TABLE
local limb = {
    root = {centerX, centerY},
    
    lengths = {
        80,
        120,
        40,
        -- ADD MORE HERE
    },
    segmentModificationSpeed = 50,
    
    angles = {
        -135,
        90,
        90,
        -- ADD MORE HERE
    },
    angleModificationSpeed = math.pi / 4,
    
    jointRadius = 10,
    jointRadiusDecreaseRate = 1.4,

    activeColor = color.white,
    inactiveColor = color.gray,
}


----- WINDOW CREATION
local function initWindow(width, height, title, color)
	love.window.setTitle(title)
	love.graphics.setBackgroundColor(color)
	love.window.setMode(width, height, {fullscreen = window.fullscreen, resizable = false})
end


----- CONVERT RADS TO DEGS
local function convertAngles()
    for angle = 1, #limb.angles do
        limb.angles[angle] = math.rad(limb.angles[angle])
    end
end


----- FORWARD KINEMATICS
limb.jointPos = {}
local tipX, tipY = limb.root[1], limb.root[2]

local function forwardKinematics()
    limb.jointPos = {}
    local relativeAngle = limb.angles[1]
    table.insert(
        limb.jointPos, {limb.root[1] + limb.lengths[1] * math.cos(relativeAngle),
        limb.root[2] + limb.lengths[1] * math.sin(relativeAngle),
        limb.jointRadius}
    )
    for segment = 2, #limb.lengths do
        relativeAngle = 0
        for joint = 1, segment do
            relativeAngle = relativeAngle + limb.angles[joint]
        end
        table.insert(limb.jointPos,
            {limb.jointPos[segment - 1][1] + limb.lengths[segment] * math.cos(relativeAngle), 
            limb.jointPos[segment - 1][2] + limb.lengths[segment] * math.sin(relativeAngle),
            limb.jointPos[segment - 1][3] / limb.jointRadiusDecreaseRate}
        )
    end
    tipX, tipY = limb.jointPos[#limb.jointPos][1], limb.jointPos[#limb.jointPos][2]
end

----- INTERACTIVITY
local keyStates = {}
local function pressed(key)
    local down = love.keyboard.isDown(key)

    if down and not keyStates[key] then
        keyStates[key] = down
        return true
    else
        keyStates[key] = love.keyboard.isDown(key)
        return false
    end
end

local selectedSegment = 1
local function checkSegmentSelection()
    for key = 1, #limb.lengths do
        if pressed(tostring(key)) then
            selectedSegment = key
        end
    end
end

local angleModificationDirection = 'clockwise'
local function checkAngleModification()
    if love.keyboard.isDown('right') then
        angleModificationDirection = 'clockwise'
        return true
    elseif love.keyboard.isDown('left') then
        angleModificationDirection = 'counterclockwise'
        return true
    end
end

local lengthModificationType = 'extend'
local function checkLengthModification()
    if love.keyboard.isDown('up') then
        lengthModificationType = 'extend'
        return true
    elseif love.keyboard.isDown('down') then
        lengthModificationType = 'retract'
        return true
    end
end

local function modifyAngle(number, direction, speed, deltaTime)
    if direction == 'counterclockwise' then
        speed = -speed
    end
    limb.angles[number] = limb.angles[number] + speed * deltaTime
end

local function modifyLength(number, action, speed, deltaTime)
    if action == 'retract' then
        speed = -speed
    end
    if limb.lengths[number] > 0 or action == 'extend' then
        limb.lengths[number] = limb.lengths[number] + speed * deltaTime
    else
        limb.lengths[number] = 0
    end
end

local function trimAngles()
    for angle = 1, #limb.angles do
        if math.abs(limb.angles[angle]) >= math.pi * 2 then
            limb.angles[angle] = math.fmod(limb.angles[angle], math.pi * 2)
        end
    end
end

local function drawJoint(x, y, radius, color)
    love.graphics.setColor(window.color)
    love.graphics.circle('fill', x, y, radius)
    love.graphics.setColor(color)
    love.graphics.circle('line', x, y, radius)
end




----- INIT
function love.load()
    initWindow(window.width, window.height, window.title, window.color)
    convertAngles()
    forwardKinematics()
end

----- DRAW
function love.draw()
    
    if selectedSegment == 1 then
        love.graphics.setColor(limb.activeColor)
    else
        love.graphics.setColor(limb.inactiveColor)
    end
    love.graphics.line(limb.root[1], limb.root[2], limb.jointPos[1][1], limb.jointPos[1][2])
    drawJoint(limb.root[1], limb.root[2], limb.jointPos[1][3], limb.inactiveColor)
    for segment = 2, #limb.jointPos do
        if selectedSegment == segment then
            love.graphics.setColor(limb.activeColor)
        else
            love.graphics.setColor(limb.inactiveColor)
        end
        love.graphics.line(
            limb.jointPos[segment - 1][1], limb.jointPos[segment - 1][2],
            limb.jointPos[segment][1], limb.jointPos[segment][2]
        )
        drawJoint(limb.jointPos[segment - 1][1], limb.jointPos[segment - 1][2], limb.jointPos[segment][3], limb.inactiveColor)
    end
    drawJoint(tipX, tipY, limb.jointPos[#limb.jointPos][3] / limb.jointRadiusDecreaseRate, limb.inactiveColor)
end

----- UPDATE
function love.update(dt)
    checkSegmentSelection()
    if checkAngleModification() then
        modifyAngle(selectedSegment, angleModificationDirection, limb.angleModificationSpeed, dt)
        trimAngles()
        forwardKinematics()
    end
    if checkLengthModification() then
        modifyLength(selectedSegment, lengthModificationType, limb.segmentModificationSpeed, dt)
        trimAngles()
        forwardKinematics()
    end
end