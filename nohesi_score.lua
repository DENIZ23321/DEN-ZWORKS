--[[
YENİ PROFESYONEL PUAN SİSTEMİ - HUD FIX
liderlik-tablosu
... (aynı kurallar)
CSP Client Lua - Extra Options SCRIPT_TYPE=client
]]

-- Event for server (ScoreTrackerPlugin uyumlu)
local msg = ac.OnlineEvent({
    ac.StructItem.key("makasScoreEnd"),
    Score = ac.StructItem.int64(),
    Multiplier = ac.StructItem.int32(),
    Car = ac.StructItem.string(64),
})

-- Config
local MAX_PROX_DIST = 3.0
local MIN_OVERTAKE_REL_SPEED = 10  -- km/h
local COMBO_DECAY_TIME = 8
local STEER_INTENSITY_SCALE = 15

-- State
local timePassed = 0
local totalScore = 0
local makasCount = 0
local combo = 1
local comboProgress = 0
local highestScore = 0
local comboDecayTimer = 0
local aiStates = {}
local messages = {}
local glitter = {}
local glitterCount = 0
local comboColor = 0

-- Functions (aynı)
local function get_base_points(speedKmh)
    if speedKmh < 60 then return 0 end
    if speedKmh <= 80 then
        return 12 + (speedKmh - 60) / 20 * 3
    elseif speedKmh <= 100 then
        return 15
    elseif speedKmh <= 120 then
        return 18 + (speedKmh - 100) / 20 * 4
    elseif speedKmh <= 150 then
        return 22 + (speedKmh - 120) / 30 * 6
    elseif speedKmh <= 180 then
        return 28 + (speedKmh - 150) / 30 * 7
    else
        return 35
    end
end

local function get_combo_step(speedKmh)
    if speedKmh < 100 then return 30
    elseif speedKmh < 150 then return 20
    else return 10 end
end

local function get_prox_mult(dist)
    if dist < 1.5 then return 2.0
    elseif dist < 2.0 then return 1.8
    elseif dist < 2.5 then return 1.4
    elseif dist < 3.0 then return 1.1
    else return 0 end
end

local function reset_ai_state(idx)
    aiStates[idx] = {last_long = 0, min_lat = math.huge, max_intensity = 0}
end

local function addMessage(text, mood)
    for i = math.min(#messages + 1, 5), 2, -1 do
        messages[i] = messages[i - 1]
    end
    messages[1] = {text = text, age = 0, targetPos = 1, currentPos = 1, mood = mood}
    if mood == 1 then
        for i = 1, 30 do
            local dir = vec2(math.random() - 0.5, math.random() - 0.5)
            glitterCount = glitterCount + 1
            glitter[glitterCount] = {
                color = rgbm.new(hsv(math.random() * 360, 1, 1):rgb(), 1),
                pos = vec2(80, 140) + dir * vec2(40, 20),
                velocity = dir:normalize():scale(0.3 + math.random() * 0.2),
                life = 0.8 + 0.4 * math.random()
            }
        end
    end
end

function script.update(dt)
    timePassed = timePassed + dt
    comboDecayTimer = comboDecayTimer + dt
    if comboDecayTimer > COMBO_DECAY_TIME and combo > 1 then
        addMessage("Combo Koptu!", -1)
        combo = 1
        comboProgress = 0
        comboDecayTimer = 0
    end

    local player = ac.getCar(0)
    if not player then return end
    local pstate = ac.getCarState(0)
    local sim = ac.getSimState()

    local fwd = (player.orientation * vec3(0, 0, 1)):normalize()
    local up = (player.orientation * vec3(0, 1, 0)):normalize()

    for i = 1, sim:carsCount() - 1 do
        local ai = ac.getCar(i)
        if ai and ai.aiControlled then
            if not aiStates[i] then reset_ai_state(i) end
            local s = aiStates[i]

            local rel_pos = ai.position - player.position
            local rel_pos_local = player.orientation:inverse() * rel_pos
            local lat_dist = math.abs(rel_pos_local.x)
            local rel_long = rel_pos_local.z

            local rel_vel = player.velocity - ai.velocity
            local rel_vel_long = rel_vel:dot(fwd) / 3.6

            if lat_dist < MAX_PROX_DIST then
                s.min_lat = math.min(s.min_lat, lat_dist)
                local yaw_rate = math.abs(pstate.angularVelocity:dot(up))
                s.max_intensity = math.max(s.max_intensity, yaw_rate)
            end

            if rel_vel_long > MIN_OVERTAKE_REL_SPEED then
                if s.last_long > 0 and rel_long < 0 then
                    local speed = player.speedKmh
                    local base_p = get_base_points(speed)
                    if base_p > 0 then
                        local prox_m = get_prox_mult(s.min_lat)
                        local steer_m = 1 + math.min(0.8, s.max_intensity / STEER_INTENSITY_SCALE)
                        local points = math.floor(base_p * prox_m * steer_m * combo)
                        totalScore = totalScore + points
                        makasCount = makasCount + 1

                        local step = get_combo_step(speed)
                        comboProgress = comboProgress + 1 / step
                        while comboProgress >= 1 do
                            combo = combo + 1
                            comboProgress = comboProgress - 1
                            addMessage("COMBO! " .. combo .. "x", 1)
                        end

                        addMessage("Makas +" .. points .. " (" .. string.format("%.1f", s.min_lat) .. "m)", 1)
                        comboDecayTimer = 0

                        if totalScore > highestScore then
                            highestScore = totalScore
                            msg{
                                Score = totalScore,
                                Multiplier = combo,
                                Car = ac.getCarName(0)
                            }
                        end
                    end
                    s.min_lat = math.huge
                    s.max_intensity = 0
                end
            end
            s.last_long = rel_long
        end
    end

    if totalScore > highestScore then
        highestScore = totalScore
    end
end

local function updateMessages(dt)
    comboColor = comboColor + dt * 15 * combo
    if comboColor > 360 then comboColor = comboColor - 360 end

    for i = 1, #messages do
        local m = messages[i]
        m.age = m.age + dt
        m.currentPos = ui.applyLag(m.currentPos, m.targetPos, 0.8, dt)
    end

    for i = glitterCount, 1, -1 do
        local g = glitter[i]
        g.pos = g.pos + g.velocity
        g.velocity.y = g.velocity.y + 0.015
        g.life = g.life - dt
        g.color.a = math.saturate(g.life * 2.5)
        if g.life < 0 then
            glitter[i] = glitter[glitterCount]
            glitterCount = glitterCount - 1
        end
    end

    if combo > 1 and math.random() > 0.95 then
        for _ = 1, math.min(5, combo) do
            local dir = vec2(math.random() - 0.5, math.random() - 0.5)
            glitterCount = glitterCount + 1
            glitter[glitterCount] = {
                color = rgbm.new(hsv(math.random() * 360, 1, 1):rgb(), 1),
                pos = vec2(200, 80) + dir * vec2(30, 15),
                velocity = dir:normalize():scale(0.15 + math.random() * 0.15),
                life = 0.6 + 0.4 * math.random()
            }
        end
    end
end

function script.drawUI()
    local uiState = ac.getUIState()
    updateMessages(uiState.dt)

    local player = ac.getCar(0)
    if not player then return end

    local colorDark = rgbm(0.3, 0.3, 0.3, 0.9)
    local colorGrey = rgbm(0.6, 0.6, 0.6, 1)
    local colorAccent = rgbm(0.2, 0.8, 1, 1)
    local colorCombo = rgbm.new(hsv(comboColor, math.saturate(combo / 8), 1):rgb(), math.saturate(combo / 5))

    -- HUD SOL ÜST - SINGLE SCREEN İÇİN (triple için 1700,50 yap)
    ui.beginTransparentWindow("makasScore", vec2(20, 40), vec2(380, 280))
    ui.beginOutline()

    ui.dwriteText(math.floor(totalScore) .. " pts", "Center", rgbm(1,1,1,1), vec2(0, 20))
    ui.dwriteText(makasCount .. " Makas", "Center", colorGrey, vec2(-60, 45))
    ui.sameLine(120)
    ui.dwriteText(combo .. "x", "Center", colorCombo, vec2(0, 45))
    
    ui.pushDwriteFont("Arial Bold", 28)
    ui.dwriteText("REKOR: " .. math.floor(highestScore), "Center", colorAccent, vec2(0, 85))
    ui.popDwriteFont()

    ui.endOutline(rgbm(0,0,0,0.4))
    ui.endTransparentWindow()

    -- Messages (aynı window içinde değil, overlay gibi)
    ui.pushDwriteFont("Arial", 20)
    local startPos = vec2(30, 160)
    for i = 1, #messages do
        local m = messages[i]
        local f = math.saturate(1 - m.age / 3) * math.saturate(5 - m.currentPos)
        ui.setCursor(startPos + vec2((1 - f * f * 40), (m.currentPos - 1) * 26))
        local col = m.mood == 1 and rgbm(0.2, 1, 0.4, f) or
                    m.mood == -1 and rgbm(1, 0.3, 0.3, f) or rgbm(1,1,1,f)
        ui.dwriteText(m.text, "Left", col, vec2(0,0))
    end
    ui.popDwriteFont()

    -- Glitter (screen relative)
    ui.pushClipRect(vec4(0, 0, ui.screenWidth(), ui.screenHeight()))
    for i = 1, glitterCount do
        local g = glitter[i]
        ui.drawLine(g.pos - g.velocity * 2, g.pos + g.velocity * 2, g.color, 1.5)
    end
    ui.popClipRect()

    -- Eski mesajları temizle
    for i = #messages, 1, -1 do
        if messages[i].age > 4 then
            table.remove(messages, i)
        end
    end
end

function script.mapLoaded()
    totalScore = 0
    makasCount = 0
    combo = 1
    comboProgress = 0
    comboDecayTimer = 0
    aiStates = {}
    messages = {}
    glitter = {}
    glitterCount = 0
    timePassed = 0
    ac.log("Makas Score HUD Loaded!")  -- CSP logda gör
end
