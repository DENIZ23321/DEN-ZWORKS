-- makas_pro.lua
-- GitHub Raw ile yüklemek için hazır
-- CSP Client Lua - 2025 stabil

local score = 0
local makas = 0
local combo = 1
local combo_timer = 0
local rekor = 0

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

function script.update(dt)
    local car = ac.getCar(0)
    if not car or car.speedKmh < 60 then return end

    local sim = ac.getSim()
    local closest_dist = 9999
    local closest_car = nil

    for i = 1, sim.carsCount - 1 do
        local other = ac.getCar(i)
        if other and other.isConnected then
            local dist = (car.position - other.position):length()
            if dist < closest_dist then
                closest_dist = dist
                closest_car = other
            end
        end
    end

    if closest_dist < 3.0 and closest_car then
        local prox = get_prox_mult(closest_dist)
        local base = get_base_points(car.speedKmh)
        local steer_bonus = math.min(math.abs(car.steerAngle) * 0.02, 1.5)
        local pts = math.floor(base * prox * combo * (1 + steer_bonus))

        if pts > 0 then
            score = score + pts
            makas = makas + 1
            combo_timer = 8  -- 8 saniye reset süresi

            -- Kombo ilerlemesi
            local step = get_combo_step(car.speedKmh)
            if makas % step == 0 then
                combo = combo + 1
            end

            -- Rekor & server bildirimi
            if score > rekor then
                rekor = score
                ac.sendChatMessage("Makas Rekor: " .. math.floor(score) .. " pts x" .. combo)
            end
        end
    end

    -- Combo decay
    if combo_timer > 0 then
        combo_timer = combo_timer - dt
    else
        if combo > 1 then ac.sendChatMessage("Combo koptu!") end
        combo = 1
    end
end

function script.drawUI()
    local screen = ui.screenSize()

    -- Sağ üst köşe (triple için de çalışır)
    ui.beginTransparentWindow("MakasHUD", vec2(screen.x - 420, 40), vec2(400, 180))
    ui.beginOutline()

    ui.pushFont(ui.Font.Monospace, 34, ui.FontFlag.Bold)
    ui.text("MAKAS SKOR", rgbm(1, 0.8, 0, 1))
    ui.popFont()

    ui.pushFont(ui.Font.Monospace, 42)
    ui.text(math.floor(score) .. " pts", rgbm(1,1,1,1))
    ui.popFont()

    ui.pushFont(ui.Font.Monospace, 28)
    ui.text("x" .. combo .. " combo", rgbm(0.1, 0.9, 0.1, 1))
    ui.text(makas .. " makas", rgbm(0.8, 0.8, 0.8, 1))
    ui.text("Rekor: " .. math.floor(rekor), rgbm(0.2, 0.8, 1, 1))
    ui.popFont()

    ui.endOutline(rgbm(0,0,0,0.7))
    ui.endTransparentWindow()
end

function script.mapLoaded()
    score = 0
    makas = 0
    combo = 1
    rekor = 0
    ac.log("Makas Pro HUD GitHub Raw ile yüklendi!")
end