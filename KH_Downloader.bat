<# :
@echo off
setlocal
title KHInsider Downloader Pro
set "BATCH_PATH=%~f0"
powershell -NoProfile -STA -ExecutionPolicy Bypass -Command "Invoke-Expression ([System.IO.File]::ReadAllText($env:BATCH_PATH, [System.Text.Encoding]::UTF8))"
pause
exit /b
#>

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Web, System.Windows.Forms
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 路徑追蹤 (Registry)
$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$guid = "{374DE290-123F-4565-9164-39C4925E467B}"
$rawPath = Get-ItemPropertyValue -Path $regKey -Name $guid -ErrorAction SilentlyContinue
$dlPath = if ($rawPath -match "%") { [System.Environment]::ExpandEnvironmentVariables($rawPath) } else { $rawPath }
if (-not $dlPath) { $dlPath = Join-Path $env:USERPROFILE "Downloads" }

$cfg = @{
    Url     = ""
    Delay   = 2
    Retries = 3
    BaseDir = Join-Path $dlPath "KS_Downloads"
    Mode    = "FLAC_PRIORITY"
    Lang    = "ZH"
    UA      = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}

$i18n = @{
    "ZH" = @{
        "title"   = "       KHInsider 萬用下載工具"
        "opt_url" = "  [1] 設定專輯網址 : "
        "opt_del" = "  [2] 下載延遲秒數 : "
        "opt_ret" = "  [3] 失敗重試次數 : "
        "opt_dir" = "  [4] 選擇儲存目錄 : "
        "opt_mod" = "  [5] 下載模式切換 : "
        "opt_lan" = "  [6] 語言切換/Lang: "
        "mode_f"  = "優先 FLAC，無則 MP3"
        "mode_m"  = "僅下載 MP3"
        "inf"     = "∞ 無限重試"
        "no_ret"  = "不重試 (失敗即跳過)"
        "desc_a"  = "  注意：將自動建立 [專輯名稱] 資料夾"
        "start"   = "  [S] 開始下載 (Start)"
        "exit"    = "  [X] 離開程式 (Exit)"
        "prompt"  = "請選擇操作... "
        "err_url" = "[錯誤] 請輸入正確網址！"
        "err_404" = "[錯誤] 網頁不存在 (404) 或連線超時。"
        "err_nos" = "[錯誤] 找不到歌曲。請確認網址正確。"
        "err_del" = "[錯誤] 延遲不可低於 2 秒。"
        "parsing" = "[*] 正在解析網址與校驗本地檔案..."
        "done"    = "完成"
        "skip"    = "校驗通過(跳過)"
        "mismatch"= "校驗不符(修復中)"
        "rep_t"   = "                下載任務報告"
        "rep_s"   = " 成功: "
        "rep_f"   = " | 失敗: "
        "rep_r"   = " [R] 返回選單 | [X] 離開"
    }
    "EN" = @{
        "title"   = "       KHInsider Multi-Downloader"
        "opt_url" = "  [1] Set Album URL  : "
        "opt_del" = "  [2] Download Delay : "
        "opt_ret" = "  [3] Retry Limit    : "
        "opt_dir" = "  [4] Target Folder  : "
        "opt_mod" = "  [5] Toggle Mode    : "
        "opt_lan" = "  [6] Language/語系  : "
        "mode_f"  = "FLAC Priority (Fallback MP3)"
        "mode_m"  = "MP3 Only"
        "inf"     = "∞ Infinite"
        "no_ret"  = "None (Skip on error)"
        "desc_a"  = "  Note: Will create [Album Name] subfolder"
        "start"   = "  [S] Start Download"
        "exit"    = "  [X] Exit"
        "prompt"  = "Select an option... "
        "err_url" = "[Error] Invalid URL!"
        "err_404" = "[Error] URL not found (404)"
        "err_nos" = "[Error] No tracks found."
        "err_del" = "[Error] Minimum delay is 2s."
        "parsing" = "[*] Verifying tracks and local files..."
        "done"    = "Done"
        "skip"    = "Verified"
        "mismatch"= "Integrity Mismatch (Repairing)"
        "rep_t"   = "               Download Report"
        "rep_s"   = " Success: "
        "rep_f"   = " | Failed: "
        "rep_r"   = " [R] Return | [X] Exit"
    }
}

function T($key) { return $i18n[$cfg.Lang][$key] }

function Invoke-Menu {
    while ($true) {
        while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }
        Clear-Host
        $modeStr = if ($cfg.Mode -eq "FLAC_PRIORITY") { T "mode_f" } else { T "mode_m" }
        $retryDisplay = switch ($cfg.Retries) { 0 { T "no_ret" } 999 { T "inf" } Default { "$($cfg.Retries)" } }

        Write-Host "======================================================" -ForegroundColor Cyan
        Write-Host (T "title") -ForegroundColor Green
        Write-Host "======================================================" -ForegroundColor Cyan
        Write-Host (T "opt_url") -NoNewline; Write-Host "$($cfg.Url)" -ForegroundColor Yellow
        Write-Host (T "opt_del") -NoNewline; Write-Host "$($cfg.Delay) s"
        Write-Host (T "opt_ret") -NoNewline; Write-Host "$retryDisplay"
        Write-Host (T "opt_dir") -NoNewline; Write-Host "$($cfg.BaseDir)" -ForegroundColor Cyan
        Write-Host (T "opt_mod") -NoNewline; Write-Host "$($cfg.Mode) ($modeStr)" -ForegroundColor Magenta
        Write-Host (T "opt_lan") -NoNewline; Write-Host "$($cfg.Lang)" -ForegroundColor Green
        Write-Host "------------------------------------------------------" -ForegroundColor Cyan
        Write-Host (T "desc_a") -ForegroundColor Gray
        Write-Host (T "start") -ForegroundColor Yellow
        Write-Host (T "exit") -ForegroundColor Red
        Write-Host "======================================================" -ForegroundColor Cyan
        Write-Host (T "prompt") -NoNewline

        $opt = ""
        while ($true) {
            $key = [Console]::ReadKey($true).KeyChar.ToString().ToUpper()
            if ("123456SX".Contains($key)) { $opt = $key; break }
        }

        switch ($opt) {
            "1" { $val = Read-Host "`n[URL]"; if ($val) { $cfg.Url = $val.Trim(' ','"') } }
            "2" { $val = Read-Host "`n[Delay]"; if ($val -as [int] -ge 2) { $cfg.Delay = [int]$val } }
            "3" { $val = Read-Host "`n[Retry]"; $v = $val -as [int]; if ($v -ge 99) { $cfg.Retries = 999 } else { $cfg.Retries = $v } }
            "4" { 
                $fd = New-Object System.Windows.Forms.FolderBrowserDialog
                $fd.SelectedPath = $cfg.BaseDir
                if ($fd.ShowDialog() -eq "OK") { $cfg.BaseDir = $fd.SelectedPath }
            }
            "5" { $cfg.Mode = if($cfg.Mode -eq "FLAC_PRIORITY"){"MP3_ONLY"}else{"FLAC_PRIORITY"} }
            "6" { $cfg.Lang = if($cfg.Lang -eq "ZH"){"EN"}else{"ZH"} }
            "X" { exit }
            "S" { if ($cfg.Url -match 'https?://') { Start-Download } else { Write-Host "`n$(T 'err_url')" -ForegroundColor Red; Start-Sleep 2 } }
        }
    }
}

function Start-Download {
    $successList = New-Object System.Collections.Generic.List[string]
    $failedList = New-Object System.Collections.Generic.List[string]
    $invChars = [System.IO.Path]::GetInvalidFileNameChars()

    try {
        Write-Host "`n$(T 'parsing')" -ForegroundColor Cyan
        try { 
            $web = Invoke-WebRequest -Uri $cfg.Url -UseBasicParsing -UserAgent $cfg.UA -TimeoutSec 15
        } catch { 
            Write-Host "`n$(T 'err_404')" -ForegroundColor Red; Start-Sleep 3; return 
        }
        
        $albumTitle = if ($web.Content -match '<h2>(.*?)</h2>') { $matches[1].Trim() } else { ($cfg.Url.TrimEnd('/') -split '/')[-1] }
        $albumTitle = [System.Web.HttpUtility]::UrlDecode($albumTitle)
        foreach ($c in $invChars) { $albumTitle = $albumTitle.Replace($c.ToString(), " ") }
        
        $outDir = Join-Path $cfg.BaseDir $albumTitle
        if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

        $decodedInputUrl = [System.Web.HttpUtility]::UrlDecode($cfg.Url).TrimEnd('/')
        $albumPathFragment = ($decodedInputUrl -replace 'https?://downloads.khinsider.com', '')

        $tracks = $web.Links | Where-Object { 
            if ($null -eq $_.href) { return $false }
            $decodedHref = [System.Web.HttpUtility]::UrlDecode($_.href)
            $decodedHref.StartsWith($albumPathFragment + "/") -and $decodedHref.Length -gt ($albumPathFragment.Length + 1)
        } | Select-Object -ExpandProperty href -Unique

        if ($null -eq $tracks -or $tracks.Count -eq 0) { Write-Host "`n$(T 'err_nos')" -ForegroundColor Red; Start-Sleep 5; return }

        foreach ($trackPage in $tracks) {
            $trackWeb = try { Invoke-WebRequest -Uri "https://downloads.khinsider.com$trackPage" -UseBasicParsing -UserAgent $cfg.UA -TimeoutSec 10 } catch { $null }
            if (-not $trackWeb) { $failedList.Add($trackPage); continue }

            $flac = $trackWeb.Links | Where-Object { $_.href -match '\.flac$' } | Select-Object -ExpandProperty href -First 1
            $mp3  = $trackWeb.Links | Where-Object { $_.href -match '\.mp3$' } | Select-Object -ExpandProperty href -First 1
            $sourceUrl = if ($cfg.Mode -eq "FLAC_PRIORITY" -and $flac) { $flac } else { $mp3 }

            if ($sourceUrl) {
                $fName = [System.Web.HttpUtility]::UrlDecode(($sourceUrl.Split('?')[0] -split '/')[-1])
                foreach ($c in $invChars) { $fName = $fName.Replace($c.ToString(), "_") }
                $finalPath = Join-Path $outDir $fName

                $serverSize = 0
                $skipFile = $false
                try {
                    $req = [System.Net.WebRequest]::Create($sourceUrl)
                    $req.Method = "HEAD"; $req.UserAgent = $cfg.UA
                    $res = $req.GetResponse(); $serverSize = $res.ContentLength; $res.Close()
                    
                    if (Test-Path -LiteralPath $finalPath) {
                        if ((Get-Item -LiteralPath $finalPath).Length -eq $serverSize) {
                            Write-Host "  [$(T 'skip')] $fName" -ForegroundColor Gray
                            $successList.Add($fName)
                            $skipFile = $true
                        } else {
                            Write-Host "  [$(T 'mismatch')] $fName" -ForegroundColor Yellow
                        }
                    }
                } catch { $serverSize = -1 }

                if ($skipFile) { continue }

                Write-Host "`n$fName" -ForegroundColor White
                $done = $false; $curr = 0
                while ($true) {
                    $tmp = $finalPath + ".tmp"
                    if (Test-Path -LiteralPath $tmp) { try { Remove-Item -LiteralPath $tmp -Force } catch {} }

                    try {
                        $client = New-Object System.Net.WebClient
                        $client.Headers.Add("User-Agent", $cfg.UA)
                        $client.Headers.Add("Referer", "https://downloads.khinsider.com$trackPage")
                        
                        $strm = $client.OpenRead($sourceUrl)
                        if ($serverSize -le 0) { $serverSize = [int64]$client.ResponseHeaders["Content-Length"] }
                        
                        $fs = [System.IO.File]::Create($tmp)
                        $buf = New-Object byte[] 65536; $t = 0
                        while (($r = $strm.Read($buf, 0, $buf.Length)) -gt 0) {
                            $fs.Write($buf, 0, $r); $t += $r
                            $pct = if($serverSize -gt 0){($t/$serverSize)*100}else{0}
                            $bar = ("#" * [Math]::Min(20, [Math]::Floor($pct/5))) + ("-" * [Math]::Max(0, 20 - [Math]::Floor($pct/5)))
                            Write-Host ("`r  [$bar] $([Math]::Round($pct,1))% | $([Math]::Round($t/1MB,2))MB / $([Math]::Round($serverSize/1MB,2))MB") -NoNewline -ForegroundColor Cyan
                        }
                        $fs.Close(); $strm.Close()
                        if (Test-Path -LiteralPath $finalPath) { Remove-Item -LiteralPath $finalPath -Force }
                        Move-Item -LiteralPath $tmp -Destination $finalPath -Force
                        Write-Host " [$(T 'done')]" -ForegroundColor Green; $successList.Add($fName); $done = $true; break
                    } catch {
                        if($fs){$fs.Close()}; if($strm){$strm.Close()}
                        if ($cfg.Retries -eq 0) { break }
                        $curr++; if ($cfg.Retries -ne 999 -and $curr -gt $cfg.Retries) { break }
                        Write-Host "`n  Retry ($curr)..." -ForegroundColor Yellow; Start-Sleep 1
                    }
                }
                if (-not $done) { $failedList.Add($fName) }
                Start-Sleep -Seconds $cfg.Delay
            }
        }
    } catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }

    Clear-Host
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host (T "rep_t") -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "$(T 'rep_s')$($successList.Count)$(T 'rep_f')$($failedList.Count)"
    Write-Host "------------------------------------------------------"
    Write-Host (T "rep_r") -ForegroundColor Yellow
    while($true){ 
        $k = [Console]::ReadKey($true).KeyChar.ToString().ToUpper()
        if($k -eq "R"){ return }; if($k -eq "X"){ exit } 
    }
}

Invoke-Menu