# 🌍 Weather Monitor Dashboard

Auto-updating global weather monitoring dashboard for 6 cities:
**Taipei · Taichung · Tokyo · Seoul · London · New York**

## Features
- Dark-themed responsive HTML dashboard
- Temperature color coding
- Hourly rain chance charts
- NE monsoon tracking for Taiwan
- Auto-updates every 3 hours via PowerShell script

## Live Dashboard
👉 View at: `https://<your-username>.github.io/weather-monitor/weather_report.html`

## Setup
1. Clone the repo
2. Run `Get-Weather.ps1` to generate the report
3. Set up the VBS daemon or Windows Task Scheduler for auto-updates

## Files
| File | Description |
|------|-------------|
| `Get-Weather.ps1` | Main weather fetching script |
| `weather_report.html` | Generated HTML dashboard |
| `WeatherDaemon.vbs` | Background auto-update daemon |
