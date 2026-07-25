# ORM-16-10 — Launcher Windows empaquetado y diagnósticos

**Estado:** contrato operativo entre **CREAR-APP** (bundle + `Alexandria.exe`), **extracción en `%LOCALAPPDATA%`**, y **visibilidad de errores** para soporte y regresiones futuras.

**Relación:** complementa ORM-16-05 (recuperación LB↔GK en disco de realm); aquí el foco es el **instalador de un solo .exe**, no el contenido del realm.

---

## 1. Layout del bundle extraído

Tras publicar con `CREAR-APP.bat`, el ZIP embebido descomprime en:

`%LOCALAPPDATA%\Alexandria\<ExtractId>\`

donde `<ExtractId>` es un identificador **fijado en tiempo de compilación** del launcher (no es el nombre del realm). Estructura esperada:

| Ruta relativa al extract root | Rol |
|--------------------------------|-----|
| `LibraryBuild\library_build.exe` (+ `data\` del realm) | Realm Library |
| `GateKeeper\Gatekeeper.exe` | Visor 3D |
| `TrainingLab\training_app.exe` | Training lab |
| `data-transfer\DataTransfer.exe` | Servicio HTTP data-transfer (**pkg**; sin Node en el PC destino) |

**Histórico (regresión conocida):** versiones anteriores ponían `DataTransfer.exe` solo en la **raíz** del extract y Library Build resolvía `data-transfer\server.js` bajo `LibraryBuild\` porque `repoRoot` en runtime empaquetado apuntaba a la carpeta `LibraryBuild`. Eso producía “Missing file: …\LibraryBuild\data-transfer\server.js”. El contrato actual es **`data-transfer\` al mismo nivel que `LibraryBuild\`** y `config.js` en el binario **pkg** usa `dirname(process.execPath)` como `ROOT_DIR` para que `out\` y `handoff\incoming\` coincidan con lo que lista Flutter.

**Library Build:** `AlexandriaPaths.dataTransferRoot` usa primero el triplete LB+GK+Lab; si falta algún hijo del launcher, **sigue** localizando la carpeta padre solo con `LibraryBuild\library_build.exe` y elige `<extract>\data-transfer` si existe `DataTransfer.exe` ahí, o la raíz del extract si solo está el exe legado en la raíz.

---

## 2. Registro en disco (launcher)

**Archivo:** `%LOCALAPPDATA%\Alexandria\diagnostics\launcher.log`

**Quién escribe:** solo el ejecutable **Alexandria** (launcher .NET). Append por línea, campos separados por tabulador:

1. Marca UTC ISO-8601  
2. Categoría: `session` | `extract` | `extract_warn` | `spawn` | `missing` | `spawn_fail` | `warn_missing` | `fatal` | `reject`  
3. Mensaje (texto en una línea; excepciones resumidas)

**Comportamiento:**

- Cada arranque válido registra `session` (`producer=Cat-Attack`, ExtractId, versión del assembly, ruta de extracción, `AppContext.BaseDirectory` del proceso).
- Cada hijo: `spawn` si arrancó, `missing` si el archivo no existe, `spawn_fail` si `Process.Start` falló.
- Si faltan piezas del bundle tras el intento de arranque, categoría `warn_missing` y **MessageBox** de advertencia listando rutas relativas y la ruta del log.
- Errores fatales (ZIP embebido, etc.): `fatal` + MessageBox con ruta del log.
- Build no publicado (`ExtractId` PLACEHOLDER): `reject` + MessageBox informativo.

**Recorte:** si el archivo supera ~480 KiB, se trunca conservando una porción final del log (evitar crecimiento ilimitado).

---

## 3. Visibilidad desde Library Build

En el **drawer**, sección de ayuda (solo Windows): entrada para abrir en el explorador la carpeta **`Alexandria\diagnostics`** (donde está `launcher.log`). Si la carpeta no existía, se crea vacía para poder pegar ahí otros adjuntos de soporte.

Constantes en código: `AlexandriaPaths.launcherDiagnosticsFolder` / `launcherDiagnosticsLogPath` (`LibraryBuild/lib/alexandria_paths.dart`).

---

## 4. Checklist para PRs que tocan empaquetado o data-transfer

- [ ] `CREAR-APP.ps1` sigue generando `data-transfer\DataTransfer.exe` (no solo en la raíz del staging).
- [ ] `launcher/Program.cs` intenta primero `data-transfer\DataTransfer.exe` y opcionalmente el legado en raíz.
- [ ] `AlexandriaPaths.dataTransferRoot` en empaquetado apunta a `<extract>\data-transfer` cuando existe el trío LB+GK+Lab en un ancestro común.
- [ ] `data-transfer/lib/config.js`: con `process.pkg`, `ROOT_DIR` = `path.dirname(process.execPath)`.
- [ ] Cambios en nombres de carpetas o EXE → actualizar este doc y las rutas en `CREAR-APP` / launcher / `AlexandriaSiblingApps` / `AlexandriaPaths.findBundleTripletInstallRoot`.

---

## 5. Trazabilidad en código

| Pieza | Ubicación |
|-------|-----------|
| Log launcher | `launcher/LauncherDiagnostics.cs`, `launcher/Program.cs` |
| Rutas data-transfer empaquetado | `LibraryBuild/lib/alexandria_paths.dart` |
| Arranque servidor DT desde LB | `LibraryBuild/lib/data_transfer_page.dart` |
| Script staging + pkg | `CREAR-APP.ps1` |
| Firma de productor / estudio | `launcher/AlexandriaBranding.cs`, metadatos en `Alexandria.csproj` |
| Desinstalador datos locales | `UNINSTALL-Alexandria.bat` + `UNINSTALL-Alexandria.ps1` (raíz del repo; copia a `deliveries\` con CREAR-APP) |

---

## 6. Desinstalador (solo datos locales del bundle)

**No** elimina Flutter, Godot, Node ni el ejecutable `Alexandria.exe` que el usuario haya copiado donde quiera.

**Sí** elimina por completo:

`%LOCALAPPDATA%\Alexandria\`

(incluye todas las carpetas `<ExtractId>`, `diagnostics\launcher.log`, realms extraídos con el launcher, etc.)

**Uso:** doble clic en **`UNINSTALL-Alexandria.bat`** (en el repo o en **`deliveries\`** junto al exe publicado). El script pide escribir **`SI`** en mayúsculas y recomienda cerrar LB/GK/Lab/DataTransfer antes.

---

## 7. Autoría (Cat-Attack)

Nombre de estudio elegido para la firma de producto: **Cat-Attack** (visible en propiedades del archivo del launcher, títulos de MessageBox, línea `producer=` en `launcher.log`, y desinstalador).

---

## Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Creación ORM-16-10: bundle, `launcher.log`, checklist, regresión server.js. |
| 1.1 | Secciones desinstalador + Cat-Attack; copia uninstall a `deliveries\` desde CREAR-APP. |
