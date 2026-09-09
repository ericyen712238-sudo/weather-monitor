Set WshShell = CreateObject("WScript.Shell")
scriptPath = "C:\Users\User\WeatherMonitor\Get-Weather.ps1"
intervalHours = 3

Do While True
    WshShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """", 0, True
    WScript.Sleep intervalHours * 3600 * 1000
Loop
