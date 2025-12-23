-- test2025.lua
-- Bu HUD çıkmazsa CSP extra scripts çalışmıyor demektir

function script.drawUI()
    ui.drawRectFilled(vec2(0, 0), ui.screenSize(), rgbm(0, 0, 0, 0.6))
    
    ui.setCursor(vec2(100, 100))
    ui.pushFont(ui.Font.Monospace, 80, ui.FontFlag.Bold)
    ui.text("CSP EXTRA SCRIPTS ÇALIŞIYOR!", rgbm(1, 0, 0, 1))
    ui.popFont()
    
    ui.setCursor(vec2(100, 220))
    ui.pushFont(ui.Font.Monospace, 50)
    ui.text("Eğer bunu görüyorsan her şey tamam!", rgbm(0, 1, 0, 1))
    ui.popFont()
    
    ac.log("HUD ÇALIŞIYOR - " .. os.date("%H:%M:%S"))
end

function script.update(dt)
    ac.log("UPDATE çalışıyor")
end

function script.mapLoaded()
    ac.sendChatMessage("CSP TEST SCRIPT YÜKLENDİ")
    ac.log("=== CSP TEST BAŞARILI ===")
end