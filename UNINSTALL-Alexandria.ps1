# Alexandria - desinstalador de datos locales (Cat-Attack)
# Quita %LOCALAPPDATA%\Alexandria (extracciones, diagnostics, logs del launcher).
# No desinstala Flutter, Godot ni Node del sistema.

$ErrorActionPreference = 'Stop'
$AlexRoot = Join-Path $env:LOCALAPPDATA 'Alexandria'

Write-Host ''
Write-Host '  Alexandria - desinstalador' -ForegroundColor Cyan
Write-Host '  Creado por Cat-Attack' -ForegroundColor DarkGray
Write-Host ''

if (-not (Test-Path -LiteralPath $AlexRoot)) {
  Write-Host 'No existe la carpeta de datos:' -ForegroundColor Yellow
  Write-Host "  $AlexRoot"
  Write-Host 'Nada que borrar.' -ForegroundColor Green
  exit 0
}

$size = (Get-ChildItem -LiteralPath $AlexRoot -Recurse -Force -ErrorAction SilentlyContinue |
  Measure-Object -Property Length -Sum).Sum
$mb = if ($null -ne $size) { [math]::Round($size / 1MB, 2) } else { 0 }

Write-Host 'Se borrara por completo:' -ForegroundColor Yellow
Write-Host "  $AlexRoot"
Write-Host "  (aprox. $mb MB bajo esa ruta)" -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Cierra Library Build, GateKeeper, Training Lab y DataTransfer antes de continuar.' -ForegroundColor Yellow
Write-Host ''

$ok = Read-Host 'Escribe SI en mayusculas para confirmar'
if ($ok -ne 'SI') {
  Write-Host 'Cancelado.' -ForegroundColor Gray
  exit 1
}

try {
  Remove-Item -LiteralPath $AlexRoot -Recurse -Force -ErrorAction Stop
  Write-Host ''
  Write-Host 'Listo. Carpeta eliminada.' -ForegroundColor Green
}
catch {
  Write-Host ''
  # No usar "Error: $_" entre comillas dobles: el mensaje puede llevar comillas y romper el parseo.
  Write-Host ('Error: ' + $_.Exception.Message) -ForegroundColor Red
  Write-Host 'Cierra procesos que usen archivos dentro de esa carpeta e intenta de nuevo.' -ForegroundColor Yellow
  exit 1
}
