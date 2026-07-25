# Entrega

**Generar el ejecutable:** en la raíz de Alexandria, doble clic en **`CREAR-APP.bat`**. En la máquina de compilación hace falta Flutter, Godot, .NET 8 SDK y Node.js (solo para empaquetar `data-transfer` con `pkg`).

**Salida:** **`deliveries\Alexandria-YYYYMMDD-HHMMSS.exe`** — un solo archivo.

**En el otro PC:** copia **solo ese `.exe`**. No hace falta PowerShell, npm ni descomprimir nada a mano. La primera ejecución extrae el contenido a `%LOCALAPPDATA%\Alexandria\<id>\` y arranca LibraryBuild, GateKeeper, Training y DataTransfer.

**Requisitos en el PC destino:** Visual C++ Redistributable x64 (típico para apps Flutter/Godot en Windows). El launcher incluye runtime .NET embebido (self-contained).
