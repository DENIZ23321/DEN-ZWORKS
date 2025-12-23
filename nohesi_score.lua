--[[
MİNİMAL HUD TEST - CSP CLIENT LUA
CSP Extra.ini: SCRIPT_TYPE=client ACTIVE=1 SCRIPT_FILE=test_hud.lua
F11 CSP console'a bak: loglar gelecek
AI yarışı başlat, HUD sol üstte "TEST 123" çıkacak
]]

local testCounter = 0

function script.update(dt)
    testCounter = testCounter + dt
    ac.log("UPDATE CALLED: " .. math.floor(testCounter))
    
    local player = ac.getCar(0)
    if player then
        ac.log("PLAYER FOUND: " .. player.speedKmh)
    end
end

function script.drawUI()
    ac.log("DRAWUI CALLED")
    
    -- Süper basit pencere: sol üst, büyük
    ui.beginTransparentWindow("testHud", vec2(10, 10), vec2(500, 300))
    ui.beginOutline()
    
    -- Background
    ui.rectFilled(vec2(0, 0), vec2(500, 300), rgbm(0.1, 0.1, 0.1, 0.8))
    
    -- Basit textler - font gerekmez
    ui.dwriteText("TEST HUD ÇALIŞIYOR! 🔥", "Center", rgbm(1,1,1,1), vec2(0, 30), vec2(500, 40))
    ui.dwriteText("Counter: " .. math.floor(testCounter), "Center", rgbm(0.2, 0.8, 1,1), vec2(0, 80))
    
    local player = ac.getCar(0)
    if player then
        ui.dwriteText("Hız: " .. math.floor(player.speedKmh) .. " kmh", "Center", rgbm(0,1,0.5,1), vec2(0, 130))
        ui.dwriteText("Toplam: 0 pts | Makas: 0 | Combo: 1x", "Center", rgbm(1,0.8,0.2,1), vec2(0, 180))
    else
        ui.dwriteText("PLAYER YOK - Practice/Quali?", "Center", rgbm(1,0.3,0.3,1), vec2(0, 130))
    end
    
    ui.dwriteText("CSP Log F11'e bak! (extra.ini OK?)", "Center", rgbm(0.6,0.6,0.6,1), vec2(0, 230))
    
    ui.endOutline(rgbm(0,0,0,0.5))
    ui.endTransparentWindow()
end

function script.mapLoaded()
    testCounter = 0
    ac.log("=== MAKAS HUD TEST LOADED ===")
    ac.log("CSP Extra.ini kontrol et:")
    ac.log("[SCRIPT_1]")
    ac.log("SCRIPT_TYPE=client")
    ac.log("SCRIPT_FILE=test_hud.lua")
    ac.log("ACTIVE=1")
end
