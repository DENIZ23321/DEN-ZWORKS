-- Makas Score Pro - AGALAR İÇİN SON VERSİYON
-- F8 > Apps > Makas Score Pro > Enable

local score = 0
local makasCount = 0
local combo = 1
local comboProgress = 0
local rekor = 0
local decayTimer = 0
local aiStates = {}
local messages = {}

local MAX_PROX = 3.0
local MIN_REL_SPEED = 10
local COMBO_DECAY = 8
local STEER_SCALE = 15

local function get_base_points(speed)
    if speed < 60 then return 0 end
    if speed <= 80 then return 13 end
    if speed <= 100 then return 15 end
    if speed <= 120 then return math.random(18,22) end
    if speed <= 150 then return math.random(22,28) end
    if speed <= 180 then return math.random(28,35) end
    return 35
end

local function get_prox_mult(dist)
    if dist < 1.5 then return 2.0
    elseif dist < 2.0 then return 1.8
    elseif dist < 2.5 then return 1.4
    elseif dist < 3.0 then return 1.1
    else return 0 end
end

local function get_combo_step(speed)
    if speed < 100 then return 30 end
    if speed < 150 then return 20 end
    return 10
end

local function reset_ai(idx)
    aiStates[idx] = {last_long = 0, min_lat = math.huge, max_yaw = 0}
end

local function add_message(text, success)
    table.insert(messages, 1, {text = text, age = 0, success = success})
    if #messages > 5 then table.remove(messages) end
end

function script.update(dt)
    decayTimer = decayTimer + dt
    if decayTimer > COMBO_DECAY and combo > 1 then
        add_message("Combo Koptu!", false)
        combo = 1
        comboProgress = 0
        decayTimer = 0
    end

    local car = ac.getCar(0)
    if not car then return end

    local sim = ac.getSim()
    local fwd = car.orientation * vec3(0,0,1):normalize()
    local up = car.orientation * vec3(0,1,0):normalize()
    local state = ac.getCarState(0)

    for i = 1, sim.carsCount - 1 do
        local ai = ac.getCar(i)
        if ai and ai.aiControlled then
            if not aiStates[i] then reset_ai(i) end
            local st = aiStates[i]

            local rel_pos = car.orientation:inverse() * (ai.position - car.position)
            local lat = math.abs(rel_pos.x)
            local lon = rel_pos.z

            local rel_vel_long = (car.velocity - ai.velocity):dot(fwd) / 3.6

            if lat < MAX_PROX then
                st.min_lat = math.min(st.min_lat, lat)
                st.max_yaw = math.max(st.max_yaw, math.abs(state.angularVelocity:dot(up)))
            end

            if rel_vel_long > MIN_REL_SPEED and st.last_long > 0 and lon < 0 then
                local spd = car.speedKmh
                local base = get_base_points(spd)
                if base > 0 then
                    local prox = get_prox_mult(st.min_lat)
                    local steer_b = 1 + math.min(0.8, st.max_yaw / STEER_SCALE)
                    local pts = math.floor(base * prox * steer_b * combo)

                    score = score + pts
                    makasCount = makasCount + 1

                    local step = get_combo_step(spd)
                    comboProgress = comboProgress + 1 / step
                    while comboProgress >= 1 do
                        combo = combo + 1
                        comboProgress = comboProgress - 1
                        add_message("COMBO x" .. combo .. " 🔥", true)
                    end

                    add_message("Makas +" .. pts .. " (" .. string.format("%.1f m)", st.min_lat), true)
                    decayTimer = 0

                    if score > rekor then
                        rekor = score
                        ac.sendChatMessage("Yeni Rekor! " .. math.floor(rekor) .. " pts x" .. combo)
                    end
                end
                st.min_lat = math.huge
                st.max_yaw = 0
            end

            st.last_long = lon
        end
    end

    -- Mesaj yaşlarını güncelle
    for i = #messages, 1, -1 do
        messages[i].age = messages[i].age + dt
        if messages[i].age > 5 then table.remove(messages, i) end
    end
end

function script.drawUI()
    local bg = rgbm(0.05, 0.05, 0.05, 0.92)
    local text = rgbm(1,1,1,1)
    local accent = rgbm(0.1, 0.9, 1,1)
    local comboColor = rgbm(1, 0.6, 0.1, 1)

    ui.beginTransparentWindow("MakasScore", vec2(30, 30), vec2(380, 200))
    ui.beginOutline()

    ui.rectFilled(vec2(0,0), ui.windowSize(), bg)

    ui.pushFont(ui.Font.Monospace, 48, ui.FontFlag.Bold)
    ui.dwriteText(math.floor(score) .. " PTS", "Center", text, vec2(0, 20))
    ui.popFont()

    ui.pushFont(ui.Font.Monospace, 28)
    ui.dwriteText(makasCount .. " MAKAS", "Center", rgbm(0.9,0.9,0.9,1), vec2(0, 70))
    ui.sameLine(0)
    ui.dwriteText("x" .. combo, "Right", comboColor, vec2(-20, 70))
    ui.popFont()

    ui.pushFont(ui.Font.Monospace, 24, ui.FontFlag.Bold)
    ui.dwriteText("REKOR: " .. math.floor(rekor), "Center", accent, vec2(0, 110))
    ui.popFont()

    -- Mesajlar
    ui.pushFont(ui.Font.Monospace, 22)
    for i, msg in ipairs(messages) do
        local alpha = 1 - (msg.age / 5)
        local col = msg.success and rgbm(0.2,1,0.4,alpha) or rgbm(1,0.4,0.2,alpha)
        ui.dwriteText(msg.text, "Left", col, vec2(20, 140 + (i-1)*28))
    end
    ui.popFont()

    ui.endOutline(rgbm(0,0,0,0.6))
    ui.endTransparentWindow()
end

function script.draw()
    script.drawUI()
end

function script.mapLoaded()
    score = 0
    makasCount = 0
    combo = 1
    comboProgress = 0
    rekor = 0
    decayTimer = 0
    aiStates = {}
    messages = {}
    ac.log("Makas Score Pro - AGALAR Hazır!")
end