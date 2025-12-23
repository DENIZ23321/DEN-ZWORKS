--[[
YENİ PROFESYONEL MAKAS PUAN SİSTEMİ - HUD + FONKSİYON TAM
NOHESI STYLE - CSP CLIENT LUA
liderlik-tablosu uyumlu
Hız Puanları, Yakınlık x, Kombo (hız bağımlı), Steer Bonus (yaw rate)
Server: ScoreTrackerPlugin "makasScoreEnd"
CSP Extra.ini: SCRIPT_TYPE=client ACTIVE=1 SCRIPT_FILE=makas_pro.lua
]]

-- Server event
local msg = ac.OnlineEvent({
    ac.StructItem.key("makasScoreEnd"),
    Score = ac.StructItem.int64(),
    Multiplier = ac.StructItem.int32(),
    Car = ac.StructItem.string(64),
})

-- Config
local MAX_PROX = 3.0
local MIN_REL_SPEED = 10  -- km/h overtake için
local COMBO_DECAY = 8     -- sn
local STEER_SCALE = 15    -- yaw rate scale

-- State
local score = 0
local makasCount = 0
local combo = 1
local comboProgress = 0
local rekor = 0
local decayTimer = 0
local aiStates = {}       -- her AI için {last_long, min_lat, max_yaw}
local messages = {}

local function get_base_points(speed)
    if speed < 60 then return 0 end
    if speed <= 80 then return 12 + (speed - 60) / 20 * 3 end
    if speed <= 100 then return 15 end
    if speed <= 120 then return 18 + (speed - 100) / 20 * 4 end
    if speed <= 150 then return 22 + (speed - 120) / 30 * 6 end
    if speed <= 180 then return 28 + (speed - 150) / 30 * 7 end
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
    if speed < 100 then return 30
    elseif speed < 150 then return 20
    else return 10 end
end

local function reset_ai(idx)
    aiStates[idx] = {last_long = 0, min_lat = math.huge, max_yaw = 0}
end

local function add_msg(text, success)
    table.insert(messages, {text = text, age = 0, success = success or false})
    if #messages > 5 then table.remove(messages, 1) end
end

function script.update(dt)
    decayTimer = decayTimer + dt
    if decayTimer > COMBO_DECAY and combo > 1 then
        add_msg("Combo Koptu! 😤", false)
        combo = 1
        comboProgress = 0
        decayTimer = 0
    end

    local car = ac.getCar(0)
    if not car then return end
    local sim = ac.getSim()
    local state = ac.getCarState(0, ac.StateFlag.All)

    local fwd = car.orientation * vec3(0, 0, 1)
    local up = car.orientation * vec3(0, 1, 0)

    for i = 1, sim.carsCount - 1 do
        local ai = ac.getCar(i)
        if ai and ai.aiControlled then
            if not aiStates[i] then reset_ai(i) end
            local st = aiStates[i]

            local rel_pos = (car.orientation:inverse() * (ai.position - car.position))
            local lat = math.abs(rel_pos.x)
            local lon = rel_pos.z

            local rel_vel = (car.velocity - ai.velocity):dot(fwd) / 3.6  -- kmh

            -- Yakınken track et
            if lat < MAX_PROX then
                st.min_lat = math.min(st.min_lat, lat)
                local yaw = math.abs(state.angularVelocity:dot(up))
                st.max_yaw = math.max(st.max_yaw, yaw)
            end

            -- Overtake detect: arkadan öne geç
            if rel_vel > MIN_REL_SPEED and st.last_long > 0 and lon < 0 then
                local spd = car.speedKmh
                local base = get_base_points(spd)
                if base > 0 then
                    local prox = get_prox_mult(st.min_lat)
                    local steer_b = 1 + math.min(0.8, st.max_yaw / STEER_SCALE)
                    local pts = math.floor(base * prox * steer_b * combo)

                    score = score + pts
                    makasCount = makasCount + 1

                    -- Kombo progress
                    local step = get_combo_step(spd)
                    comboProgress = comboProgress + 1/step
                    while comboProgress >= 1 do
                        combo = combo + 1
                        comboProgress = comboProgress - 1
                        add_msg("COMBO x" .. combo .. " 🔥", true)
                    end

                    add_msg("Makas +" .. pts .. " (" .. string.format("%.1fm)", st.min_lat), true)
                    decayTimer = 0

                    -- Rekor update & server
                    if score > rekor then
                        rekor = score
                        msg{Score = score, Multiplier = combo, Car = ac.getCarName(0)}
                    end
                end
                -- Reset state
                st.min_lat = math.huge
                st.max_yaw = 0
            end
            st.last_long = lon
        end
    end
end

function script.drawUI()
    -- Update msgs
    for i = #messages, 1, -1 do
        messages[i].age = (messages[i].age or 0) + ac.getUIState().dt
        if messages[i].age > 4 then table.remove(messages, i) end
    end

    ui.beginTransparentWindow("MakasProHUD", vec2(50, 50), vec2(350, 200))
    ui.beginOutline()

    -- Ana skor
    ui.pushFont(ui.Font.Main, 36, ui.FontFlag.Bold)
    ui.text("MAKAS: " .. makasCount .. " ( " .. combo .. "x )", rgbm(1,1,1,1))
    ui.popFont()

    ui.pushFont(ui.Font.Main, 28, ui.FontFlag.Bold)
    ui.text("REKOR: " .. math.floor(rekor), rgbm(0.2, 0.8, 1, 1))
    ui.popFont()

    -- Mesajlar
    ui.pushFont(ui.Font.Main, 22)
    for _, msg in ipairs(messages) do
        local col = msg.success and rgbm(0.2, 1, 0.4, 1 - msg.age/4) or rgbm(1, 0.4, 0.2, 1 - msg.age/4)
        ui.text(msg.text, col)
    end
    ui.popFont()

    ui.endOutline(rgbm(0,0,0, 0.6))
    ui.endTransparentWindow()
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
    ac.log("🏁 Profesyonel Makas HUD YÜKLENDİ! AI Race dene.")
end