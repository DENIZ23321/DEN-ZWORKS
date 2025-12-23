-- NOHESI STYLE SCORE SYSTEM
-- CSP LUA SCRIPT

local score = 0
local combo = 1
local passedCars = 0
local lastPassTime = 0

function getSpeedPoints(speed)
    if speed < 60 then return 0 end
    if speed < 80 then return 13 end
    if speed < 100 then return 15 end
    if speed < 120 then return math.random(18,22) end
    if speed < 150 then return math.random(22,28) end
    if speed < 180 then return math.random(28,35) end
    return 35
end

function getProximityMultiplier(dist)
    if dist < 1.5 then return 2.0 end
    if dist < 2.0 then return 1.8 end
    if dist < 2.5 then return 1.4 end
    if dist < 3.0 then return 1.1 end
    return 1.0
end

function getComboRequirement(speed)
    if speed < 100 then return 30 end
    if speed < 150 then return 20 end
    return 10
end

function script.update(dt)
    local car = ac.getCar(0)
    if not car then return end

    local speed = car.speedKmh
    if speed < 60 then return end

    -- En yakın araç
    local closestDist = 999
    for i = 1, sim.carsCount - 1 do
        local other = ac.getCar(i)
        if other then
            local dist = car.position:distance(other.position)
            if dist < closestDist then
                closestDist = dist
            end
        end
    end

    local proximity = getProximityMultiplier(closestDist)
    local steerBonus = math.min(math.abs(car.steerAngle) * 0.25, 1.5)

    local points = getSpeedPoints(speed)
    if points == 0 then return end

    score = score + (points * proximity * combo * (1 + steerBonus))

    -- Araç geçme algısı
    if closestDist < 2.5 then
        passedCars = passedCars + 1
        lastPassTime = os.clock()
    end

    if passedCars >= getComboRequirement(speed) then
        combo = combo + 1
        passedCars = 0
    end

    -- Combo reset
    if os.clock() - lastPassTime > 3 then
        combo = 1
        passedCars = 0
    end

    -- Çarpma cezası
    if car.collided then
        combo = 1
        score = math.max(0, score - 200)
    end
end

function script.drawUI()
    ui.beginTransparentWindow("NoHesi Pro Score", vec2(50, 300), vec2(300, 140))
    ui.text("🏁 SCORE: " .. math.floor(score))
    ui.text("🔥 COMBO: x" .. combo)
    ui.text("🚗 PASSED: " .. passedCars)
    ui.endWindow()
end
