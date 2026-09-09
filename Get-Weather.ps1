$ErrorActionPreference = "SilentlyContinue"

$cities = @(
    @{ Name = "Taipei"; NameZH = "`u{53F0}`u{5317}"; Flag = "`u{1F1F9}`u{1F1FC}"; Query = "Taipei" },
    @{ Name = "Taichung"; NameZH = "`u{53F0}`u{4E2D}"; Flag = "`u{1F1F9}`u{1F1FC}"; Query = "Taichung" },
    @{ Name = "Tokyo"; NameZH = "`u{6771}`u{4EAC}"; Flag = "`u{1F1EF}`u{1F1F5}"; Query = "Tokyo" },
    @{ Name = "Seoul"; NameZH = "`u{9996}`u{723E}"; Flag = "`u{1F1F0}`u{1F1F7}"; Query = "Seoul" },
    @{ Name = "London"; NameZH = "`u{502B}`u{6566}"; Flag = "`u{1F1EC}`u{1F1E7}"; Query = "London" },
    @{ Name = "New York"; NameZH = "`u{7D10}`u{7D04}"; Flag = "`u{1F1FA}`u{1F1F8}"; Query = "New+York" }
)

$outputDir = "J:\Users\User\WeatherMonitor"
if (-not (Test-Path $outputDir)) { New-Item -Path $outputDir -ItemType Directory -Force | Out-Null }
$reportFile = Join-Path $outputDir "weather_report.html"
$timestamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
$nextUpdate = Get-Date (Get-Date).AddHours(3) -Format "yyyy/MM/dd HH:mm"

$weatherData = @()
foreach ($city in $cities) {
    try {
        $uri = "https://wttr.in/" + $city.Query + "?format=j1"
        $data = Invoke-RestMethod -Uri $uri -TimeoutSec 15
        $cur = $data.current_condition[0]
        $tod = $data.weather[0]
        $rains = $tod.hourly | ForEach-Object { [int]$_.chanceofrain }
        $maxR = ($rains | Measure-Object -Maximum).Maximum
        $hList = @()
        foreach ($h in $tod.hourly) {
            $hList += @{ Time = [int]$h.time / 100; Temp = $h.tempC; Rain = $h.chanceofrain; Desc = $h.weatherDesc[0].value.Trim() }
        }
        $weatherData += @{
            City = $city; Temp = $cur.temp_C; FeelsLike = $cur.FeelsLikeC
            Desc = $cur.weatherDesc[0].value.Trim(); Humidity = $cur.humidity
            WindDir = $cur.winddir16Point; WindSpeed = $cur.windspeedKmph
            UV = $cur.uvIndex; MaxTemp = $tod.maxtempC; MinTemp = $tod.mintempC
            MaxRain = $maxR; Hourly = $hList; Err = $null
        }
    } catch {
        $weatherData += @{ City = $city; Err = $_.Exception.Message }
    }
}

# NE Monsoon
$tpe = $weatherData | Where-Object { $_.City.Name -eq "Taipei" -and -not $_.Err }
$mLevel = "none"; $mTitle = "No NE monsoon"; $mDesc = ""
if ($tpe) {
    $wd = $tpe.WindDir; $ws = $tpe.WindSpeed; $tp = $tpe.Temp
    $isNE = $wd -match "^N$|^NE$|^NNE$|^ENE$"
    if ($isNE -and [int]$ws -ge 15) {
        $mLevel = "strong"
        $mTitle = "`u{6771}`u{5317}`u{5B63}`u{98A8}`u{660E}`u{986F}`u{589E}`u{5F37}`u{FF01}"
        $mDesc = "Wind $wd, ${ws}km/h, Temp ${tp}`u{00B0}C. Stay warm, bring umbrella."
    } elseif ($isNE) {
        $mLevel = "weak"
        $mTitle = "`u{6771}`u{5317}`u{98A8}`u{5FAE}`u{5F31}`u{FF0C}`u{6301}`u{7E8C}`u{89C0}`u{5BDF}`u{4E2D}"
        $mDesc = "Wind $wd, ${ws}km/h, Temp ${tp}`u{00B0}C. Monitoring..."
    } else {
        $mLevel = "none"
        $mTitle = "`u{76EE}`u{524D}`u{7121}`u{6771}`u{5317}`u{5B63}`u{98A8}`u{8DE1}`u{8C61}"
        $mDesc = "Wind $wd, ${ws}km/h, Temp ${tp}`u{00B0}C."
    }
}

function Get-WIcon($d) {
    if ($d -match "Clear|Sunny") { return "`u{2600}`u{FE0F}" }
    if ($d -match "Partly")     { return "`u{26C5}" }
    if ($d -match "Cloudy|Overcast") { return "`u{2601}`u{FE0F}" }
    if ($d -match "rain|Rain")  { return "`u{1F327}`u{FE0F}" }
    if ($d -match "Thunder")    { return "`u{26C8}`u{FE0F}" }
    if ($d -match "Snow")       { return "`u{2744}`u{FE0F}" }
    if ($d -match "Fog|Mist|Haze|Smok") { return "`u{1F32B}`u{FE0F}" }
    return "`u{1F324}`u{FE0F}"
}

function Get-TColor($t) {
    $v = [int]$t
    if ($v -ge 35) { return "#ef4444" }; if ($v -ge 30) { return "#f97316" }
    if ($v -ge 25) { return "#f59e0b" }; if ($v -ge 20) { return "#22c55e" }
    if ($v -ge 15) { return "#06b6d4" }; if ($v -ge 10) { return "#3b82f6" }
    return "#8b5cf6"
}

function Get-RColor($r) {
    $v = [int]$r
    if ($v -ge 60) { return "#ef4444" }; if ($v -ge 40) { return "#f97316" }
    if ($v -ge 20) { return "#f59e0b" }; return "#22c55e"
}

# Build cards
$cards = ""
foreach ($w in $weatherData) {
    if ($w.Err) {
        $cards += "<div class='card card-error'><div class='card-header'><span class='flag'>$($w.City.Flag)</span><span class='city-name'>$($w.City.NameZH)</span></div><div class='error-msg'>Query failed</div></div>`n"
        continue
    }
    $ic = Get-WIcon $w.Desc
    $tc = Get-TColor $w.Temp
    $rc = Get-RColor $w.MaxRain
    $bars = ""
    foreach ($h in $w.Hourly) {
        $bh = [Math]::Max(5, [int]$h.Rain)
        $bc = Get-RColor $h.Rain
        $bars += "<div class='bw' title='$($h.Time):00 | $($h.Temp)`u{00B0}C | Rain $($h.Rain)%'><div class='b' style='height:${bh}px;background:${bc}'></div><div class='bl'>$($h.Time)</div></div>"
    }
    $deg = "`u{00B0}"
    $lbl_feel = "`u{9AD4}`u{611F}"
    $lbl_range = "`u{9AD8}`u{4F4E}`u{6EAB}"
    $lbl_humid = "`u{6FD5}`u{5EA6}"
    $lbl_wind = "`u{98A8}`u{5411}"
    $lbl_uv = "`u{7D2B}`u{5916}`u{7DDA}"
    $lbl_rain = "`u{964D}`u{96E8}`u{6A5F}`u{7387}"
    $lbl_hourly = "`u{9010}`u{6642}`u{964D}`u{96E8}`u{6A5F}`u{7387} (%)"
    $cards += @"
<div class='card'>
<div class='card-header'><span class='flag'>$($w.City.Flag)</span><div class='ci'><span class='cn'>$($w.City.NameZH)</span><span class='ce'>$($w.City.Name)</span></div><span class='wi'>$ic</span></div>
<div class='tm' style='color:$tc'>$($w.Temp)${deg}C</div>
<div class='ds'>$($w.Desc)</div>
<div class='dg'>
<div class='di'><span class='dl'>$lbl_feel</span><span class='dv'>$($w.FeelsLike)${deg}C</span></div>
<div class='di'><span class='dl'>$lbl_range</span><span class='dv'>$($w.MinTemp)~$($w.MaxTemp)${deg}C</span></div>
<div class='di'><span class='dl'>$lbl_humid</span><span class='dv'>$($w.Humidity)%</span></div>
<div class='di'><span class='dl'>$lbl_wind</span><span class='dv'>$($w.WindDir) $($w.WindSpeed)km/h</span></div>
<div class='di'><span class='dl'>$lbl_uv</span><span class='dv'>UV $($w.UV)</span></div>
<div class='di'><span class='dl'>$lbl_rain</span><span class='dv' style='color:$rc;font-weight:700'>Max $($w.MaxRain)%</span></div>
</div>
<div class='hs'><div class='ht'>$lbl_hourly</div><div class='hc'>$bars</div></div>
</div>
"@
}

# Monsoon icons
$mIcon = "`u{2600}`u{FE0F}"
if ($mLevel -eq "strong") { $mIcon = "`u{1F30A}" }
if ($mLevel -eq "weak")   { $mIcon = "`u{1F32C}`u{FE0F}" }

# Title
$pageTitle = "`u{1F30D} `u{5168}`u{7403}`u{5929}`u{6C23}`u{76E3}`u{63A7}`u{5100}`u{8868}`u{677F}"
$subtitle = "`u{53F0}`u{5317} `u{00B7} `u{53F0}`u{4E2D} `u{00B7} `u{6771}`u{4EAC} `u{00B7} `u{9996}`u{723E} `u{00B7} `u{502B}`u{6566} `u{00B7} `u{7D10}`u{7D04}"
$updLabel = "`u{66F4}`u{65B0}`u{6642}`u{9593}"
$nextLabel = "`u{4E0B}`u{6B21}`u{66F4}`u{65B0}"
$neLabel = "`u{6771}`u{5317}`u{5B63}`u{98A8}`u{52D5}`u{614B}`u{FF1A}"

$html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Weather Monitor</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI','Microsoft JhengHei',sans-serif;background:linear-gradient(135deg,#0f172a 0%,#1e293b 50%,#0f172a 100%);color:#e2e8f0;min-height:100vh;padding:20px}
.ctn{max-width:1400px;margin:0 auto}
.hdr{text-align:center;padding:30px 0 20px}
.hdr h1{font-size:2.2em;background:linear-gradient(90deg,#60a5fa,#a78bfa,#f472b6);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:8px}
.hdr .st{color:#94a3b8;font-size:.95em}
.hdr .ut{color:#64748b;font-size:.85em;margin-top:4px}
.mb{display:flex;align-items:center;gap:16px;padding:16px 24px;border-radius:12px;margin:20px 0}
.mb-strong{background:linear-gradient(135deg,#7f1d1d,#991b1b);border:1px solid #dc2626}
.mb-weak{background:linear-gradient(135deg,#1e3a5f,#1e40af33);border:1px solid #3b82f6}
.mb-none{background:linear-gradient(135deg,#14532d33,#16a34a22);border:1px solid #22c55e44}
.mi{font-size:2em}.mt{font-size:1.1em;font-weight:700;margin-bottom:4px}.md{font-size:.9em;color:#cbd5e1}
.cg{display:grid;grid-template-columns:repeat(auto-fill,minmax(340px,1fr));gap:20px;margin-top:20px}
.card{background:linear-gradient(145deg,#1e293b,#334155);border:1px solid #475569;border-radius:16px;padding:24px;transition:transform .2s,box-shadow .2s}
.card:hover{transform:translateY(-4px);box-shadow:0 12px 40px rgba(0,0,0,.4)}
.card-error{opacity:.6;display:flex;flex-direction:column;justify-content:center;align-items:center;min-height:200px}
.error-msg{color:#f87171;font-size:1.1em;margin-top:12px}
.card-header{display:flex;align-items:center;gap:12px;margin-bottom:16px}
.flag{font-size:2em}.ci{flex:1}.cn{font-size:1.3em;font-weight:700}.ce{font-size:.8em;color:#94a3b8;display:block}.wi{font-size:2.5em}
.tm{font-size:3em;font-weight:800;line-height:1;margin-bottom:4px}
.ds{color:#94a3b8;font-size:1em;margin-bottom:16px}
.dg{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px}
.di{background:#0f172a;border-radius:8px;padding:8px 12px}
.dl{font-size:.75em;color:#64748b;display:block}.dv{font-size:.95em;font-weight:600}
.hs{border-top:1px solid #475569;padding-top:12px}
.ht{font-size:.8em;color:#64748b;margin-bottom:8px}
.hc{display:flex;justify-content:space-around;align-items:flex-end;height:80px;gap:4px}
.bw{display:flex;flex-direction:column;align-items:center;flex:1;cursor:pointer}
.b{width:100%;max-width:28px;border-radius:4px 4px 0 0;min-height:3px}
.bw:hover .b{opacity:.7}
.bl{font-size:.65em;color:#64748b;margin-top:4px}
.ft{text-align:center;color:#475569;font-size:.8em;margin-top:30px;padding:20px 0;border-top:1px solid #1e293b}
@media(max-width:768px){.cg{grid-template-columns:1fr}.hdr h1{font-size:1.6em}.tm{font-size:2.4em}}
</style>
</head>
<body>
<div class="ctn">
<div class="hdr"><h1>$pageTitle</h1><div class="st">$subtitle</div><div class="ut">$updLabel $timestamp | $nextLabel $nextUpdate</div></div>
<div class="mb mb-$mLevel"><div class="mi">$mIcon</div><div><div class="mt">$neLabel$mTitle</div><div class="md">$mDesc</div></div></div>
<div class="cg">$cards</div>
<div class="ft">Weather data from wttr.in | Auto-updated every 3 hours</div>
</div>
</body>
</html>
"@

[System.IO.File]::WriteAllText($reportFile, $html, [System.Text.Encoding]::UTF8)

# Plain text history
$historyFile = Join-Path $outputDir "weather_history.txt"
$txtLines = "=== $timestamp ===`n"
foreach ($w in $weatherData) {
    if ($w.Err) { $txtLines += "$($w.City.Name): ERROR`n" }
    else { $txtLines += "$($w.City.Name): $($w.Temp)C (feel $($w.FeelsLike)C), $($w.Desc), Humid $($w.Humidity)%, Wind $($w.WindDir) $($w.WindSpeed)km/h, Rain max $($w.MaxRain)%`n" }
}
$txtLines | Out-File -FilePath $historyFile -Encoding utf8 -Append
