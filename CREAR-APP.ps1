# Maquina de COMPILACION solamente: C:\flutter, C:\Godot, Node.js (para pkg).
# Salida: deliveries\Alexandria-YYYYMMDD-HHMMSS.exe  (UN SOLO ARCHIVO: doble clic, sin PowerShell en el destino)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutDir = Join-Path $Root "deliveries"
$LauncherDir = Join-Path $Root "launcher"
$Staging = Join-Path $env:TEMP "alexandria-stage-$Stamp"
$OutExe = Join-Path $OutDir "Alexandria-$Stamp.exe"

function Find-FlutterBat {
  $candidates = @()
  if ($env:FLUTTER_ROOT) {
    $candidates += (Join-Path $env:FLUTTER_ROOT.Trim().TrimEnd('\', '/') 'bin\flutter.bat')
  }
  foreach ($p in @(
      'C:\flutter\bin\flutter.bat',
      'C:\Flutter\bin\flutter.bat',
      'D:\flutter\bin\flutter.bat',
      (Join-Path $env:LOCALAPPDATA 'flutter\bin\flutter.bat'),
      (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'),
      (Join-Path $env:USERPROFILE 'src\flutter\bin\flutter.bat'),
      (Join-Path $env:USERPROFILE 'development\flutter\bin\flutter.bat')
    )) {
    $candidates += $p
  }
  foreach ($p in $candidates) {
    if ($p -and (Test-Path -LiteralPath $p)) { return (Resolve-Path -LiteralPath $p).Path }
  }
  $cmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }
  $where = & where.exe flutter.bat 2>$null | Select-Object -First 1
  if ($where -and (Test-Path -LiteralPath $where)) { return $where.Trim() }
  return $null
}

function Find-GodotConsoleUnder {
  param([string]$Root, [int]$Depth = 8)
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root)) { return $null }
  $hit = Get-ChildItem -LiteralPath $Root -Filter '*console.exe' -File -Recurse -Depth $Depth -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^Godot' } | Select-Object -First 1
  if ($hit) { return $hit.FullName }
  return $null
}

function Find-GodotExe {
  if ($env:GODOT) {
    $g = $env:GODOT.Trim().Trim('"')
    if (Test-Path -LiteralPath $g) { return (Resolve-Path -LiteralPath $g).Path }
  }

  foreach ($driveRoot in @('C:\', 'D:\', 'E:\')) {
    if (-not (Test-Path -LiteralPath $driveRoot)) { continue }
    $godotDirs = @(Get-ChildItem -LiteralPath $driveRoot -Directory -Filter 'Godot*' -ErrorAction SilentlyContinue)
    foreach ($dir in $godotDirs) {
      $hit = Find-GodotConsoleUnder -Root $dir.FullName -Depth 4
      if ($hit) { return $hit }
    }
  }

  $pf86 = [Environment]::GetFolderPath('ProgramFilesX86')
  $roots = @(
    'C:\Godot', 'D:\Godot', 'E:\Godot',
    (Join-Path $env:LOCALAPPDATA 'Godot'),
    (Join-Path $env:APPDATA 'Godot\versions'),
    (Join-Path $env:ProgramFiles 'Godot'),
    (Join-Path $pf86 'Godot'),
    (Join-Path $env:USERPROFILE 'scoop\apps\godot\current'),
    (Join-Path $env:USERPROFILE 'scoop\apps\godot-mono\current')
  )

  foreach ($base in $roots | Where-Object { $_ -and $_.Trim() }) {
    $hit = Find-GodotConsoleUnder -Root $base
    if ($hit) { return $hit }
  }

  $wingetPkgs = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
  if (Test-Path -LiteralPath $wingetPkgs) {
    $wgDirs = @(Get-ChildItem -LiteralPath $wingetPkgs -Directory -Filter 'GodotEngine*' -ErrorAction SilentlyContinue)
    foreach ($d in $wgDirs) {
      $hit = Find-GodotConsoleUnder -Root $d.FullName -Depth 6
      if ($hit) { return $hit }
    }
  }

  $chocoLib = 'C:\ProgramData\chocolatey\lib'
  if (Test-Path -LiteralPath $chocoLib) {
    $coDirs = @(Get-ChildItem -LiteralPath $chocoLib -Directory -Filter 'godot*' -ErrorAction SilentlyContinue)
    foreach ($d in $coDirs) {
      $hit = Find-GodotConsoleUnder -Root $d.FullName -Depth 6
      if ($hit) { return $hit }
    }
  }

  $dl = Join-Path $env:USERPROFILE 'Downloads'
  if (Test-Path -LiteralPath $dl) {
    $hit = Find-GodotConsoleUnder -Root $dl -Depth 4
    if ($hit) { return $hit }
  }

  return $null
}

$flutterBat = Find-FlutterBat
if (-not $flutterBat) {
  Write-Host "No se encontro Flutter (flutter.bat)." -ForegroundColor Red
  Write-Host "Instala Flutter o define FLUTTER_ROOT (carpeta del SDK, ej. C:\src\flutter) y vuelve a ejecutar." -ForegroundColor Yellow
  Write-Host "O anade Flutter al PATH (flutter.bat en PATH)." -ForegroundColor Yellow
  exit 1
}
Write-Host "Flutter: $flutterBat" -ForegroundColor DarkGray
$godot = Find-GodotExe
if ($godot -is [array]) { $godot = $godot[0] }
if (-not $godot) {
  Write-Host "No se encontro Godot (necesitas la build .NET, archivo tipo Godot_*_win64_console.exe)." -ForegroundColor Red
  Write-Host "Opciones:" -ForegroundColor Yellow
  Write-Host "  1) Descarga Godot .NET para Windows desde https://godotengine.org/download/windows/ y descomprime en C:\Godot (o cualquier carpeta)." -ForegroundColor Yellow
  Write-Host "  2) O define variable de usuario (ruta al *_console.exe):" -ForegroundColor Yellow
  Write-Host '     setx GODOT "C:\ruta\Godot_v4.x-stable_mono_win64_console.exe"' -ForegroundColor Gray
  Write-Host "  Cierra y vuelve a abrir CREAR-APP.bat despues de setx." -ForegroundColor Yellow
  exit 1
}
Write-Host "Godot:  $godot" -ForegroundColor DarkGray
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host "Falta Node.js en el PATH (solo para empaquetar data-transfer en un .exe con pkg)." -ForegroundColor Red
  exit 1
}

Write-Host "=== Alexandria: un solo .exe (auto-extrae en %LOCALAPPDATA%) ===" -ForegroundColor Cyan

Write-Host "[1/5] LibraryBuild..." -ForegroundColor Cyan
Push-Location (Join-Path $Root "LibraryBuild")
try {
  & $flutterBat pub get | Out-Null
  & $flutterBat build windows --release
  if ($LASTEXITCODE -ne 0) { throw "LibraryBuild $LASTEXITCODE" }
} finally { Pop-Location }
$lbRel = Join-Path $Root "LibraryBuild\build\windows\x64\runner\Release"

Write-Host "[2/5] Training..." -ForegroundColor Cyan
Push-Location (Join-Path $Root "training_app")
try {
  & $flutterBat pub get | Out-Null
  & $flutterBat build windows --release
  if ($LASTEXITCODE -ne 0) { throw "training $LASTEXITCODE" }
} finally { Pop-Location }
$trRel = Join-Path $Root "training_app\build\windows\x64\runner\Release"

Write-Host "[3/5] GateKeeper..." -ForegroundColor Cyan
$gk = Join-Path $Root "GateKeeper"
$gkExport = Join-Path $gk "export"
if (Test-Path $gkExport) { Remove-Item -Recurse -Force $gkExport }
New-Item -ItemType Directory -Force -Path $gkExport | Out-Null
& $godot --headless --path $gk --export-release "Windows Desktop" "export/Gatekeeper.exe"
if ($LASTEXITCODE -ne 0) { throw "Godot $LASTEXITCODE" }

Write-Host "[4/5] Staging + DataTransfer.exe (pkg, sin npm en el PC destino)..." -ForegroundColor Cyan
if (Test-Path $Staging) { Remove-Item -Recurse -Force $Staging }
New-Item -ItemType Directory -Force -Path $Staging | Out-Null
$lbDst = Join-Path $Staging "LibraryBuild"
$gkDst = Join-Path $Staging "GateKeeper"
$trDst = Join-Path $Staging "TrainingLab"
$ormDst = Join-Path $Staging "ORM"
New-Item -ItemType Directory -Force -Path $lbDst, $gkDst, $trDst, $ormDst | Out-Null

& robocopy $lbRel $lbDst /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy LB" }
& robocopy (Join-Path $Root "data") (Join-Path $lbDst "data") /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy data" }
& robocopy $gkExport $gkDst /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy GK" }
& robocopy $trRel $trDst /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy TR" }

$ormSrc = Join-Path $Root "ORM"
if (Test-Path $ormSrc) {
  & robocopy $ormSrc $ormDst /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy ORM" }
}

$coreSrc = Join-Path $Root "core"
if (Test-Path $coreSrc) {
  $cDst = Join-Path $Staging "core"
  New-Item -ItemType Directory -Force -Path $cDst | Out-Null
  & robocopy $coreSrc $cDst /E /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy core" }
}

$dtSrc = Join-Path $Root "data-transfer"
$dtDstDir = Join-Path $Staging "data-transfer"
New-Item -ItemType Directory -Force -Path $dtDstDir | Out-Null
Push-Location $dtSrc
try {
  if (Test-Path "package-lock.json") { npm ci 2>$null } else { npm install 2>$null }
  $dtOutBase = Join-Path $dtDstDir "DataTransfer"
  npx --yes pkg@5.8.1 server.js --targets node18-win-x64 --output $dtOutBase
  if ($LASTEXITCODE -ne 0) { throw "pkg fallo: $LASTEXITCODE" }
  $dtExe = "$dtOutBase.exe"
  if (-not (Test-Path $dtExe)) { throw "pkg no genero DataTransfer.exe en $dtDstDir" }
} finally { Pop-Location }

$extractId = [Guid]::NewGuid().ToString("N").Substring(0, 16)

$stampCs = @"
// Auto-generado por CREAR-APP.ps1
namespace Alexandria;

internal static class BuildInfo
{
    internal static readonly string ExtractId = "$extractId";
}
"@
$stampCs | Set-Content -Path (Join-Path $LauncherDir "BuildStamp.g.cs") -Encoding UTF8

$bundleZip = Join-Path $LauncherDir "bundle.zip"
if (Test-Path $bundleZip) { Remove-Item -Force $bundleZip }
$toZip = @(Get-ChildItem -LiteralPath $Staging -Force | ForEach-Object { $_.FullName })
if ($toZip.Count -eq 0) { throw "Staging vacio" }
Compress-Archive -Path $toZip -DestinationPath $bundleZip -Force

Write-Host "[5/5] dotnet publish launcher (embebe ZIP)..." -ForegroundColor Cyan
$csproj = Join-Path $LauncherDir "Alexandria.csproj"
& dotnet publish $csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true
if ($LASTEXITCODE -ne 0) { throw "dotnet publish fallo" }

$built = Join-Path $LauncherDir "bin\Release\net8.0-windows\win-x64\publish\Alexandria.exe"
if (-not (Test-Path $built)) { throw "No esta: $built" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Copy-Item -Path $built -Destination $OutExe -Force

$unBat = Join-Path $Root "UNINSTALL-Alexandria.bat"
$unPs = Join-Path $Root "UNINSTALL-Alexandria.ps1"
if (Test-Path $unBat) { Copy-Item -LiteralPath $unBat -Destination $OutDir -Force }
if (Test-Path $unPs) { Copy-Item -LiteralPath $unPs -Destination $OutDir -Force }

Remove-Item -Recurse -Force $Staging -ErrorAction SilentlyContinue
Remove-Item -Force $bundleZip -ErrorAction SilentlyContinue

$mb = [math]::Round((Get-Item $OutExe).Length / 1MB, 2)
Write-Host ""
Write-Host "LISTO. Archivo principal para el otro PC:" -ForegroundColor Green
Write-Host $OutExe
Write-Host "Tamano aprox: $mb MB (incluye runtime .NET + bundle)." -ForegroundColor Green
Write-Host "En la misma carpeta: UNINSTALL-Alexandria.bat (borra datos en %LOCALAPPDATA%\Alexandria)." -ForegroundColor DarkGray
Start-Process explorer.exe $OutDir
