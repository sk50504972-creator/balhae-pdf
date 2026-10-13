@echo off
title Balhae PDF Setup
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Join-Path $env:TEMP 'balhae-pdf-setup.ps1'; try { Invoke-WebRequest -UseBasicParsing 'https://balhae.claimworks.kr/balhae-pdf/setup.ps1' -OutFile $f; & $f } catch { Write-Host $_ -ForegroundColor Red }"
echo.
pause
