# ORM-16-05 — Recuperación LB ↔ GateKeeper (datos en disco)

**Estado:** operativo. Complementa ORM-15V3 (bridge) y ORM-16-02 (métricas). Documenta un fallo real y cómo no repetirlo.

---

## 1. Qué “conexión” existe entre LibraryBuild (LB) y GateKeeper (GK)

No hay socket ni IPC de red. El contrato es **solo filesystem**, misma raíz de repo:

| Proceso | Resolución de ruta |
|---------|---------------------|
| **LB** (Dart) | `AlexandriaPaths.realmDataRoot()` → `data/realms/<active_realm>/` |
| **GK** (Godot/C#) | `AlexandriaDataRoot.RealmDataRoot` → `C:\Alexandria\data\realms\<active_realm>\` |

`data/active_realm.txt` debe ser coherente para ambos (mismo realm activo).

GK **no abre SQLite** para el corredor principal: lee **JSON de snapshot** generado por LB.

---

## 2. Artefacto mínimo que GK espera (Spawner)

En código: `GateKeeper/Spawner.cs`

- `RealmSnapshotDir` = `Path.Combine(RealmDataRoot, "snapshot")`
- Carga principal: **`snapshot/current.json`** (y opcionalmente `snapshot/<contextKey>.json` según bridge).

Si **`snapshot/current.json` no existe**, el spawner no tiene datos válidos para alinear frames con la DB → síntoma: **“GK no lee LB” / “no hay conexión”**, aunque `alexandria.db` esté bien poblada.

LB escribe ese archivo dentro de **`runLibraryBuild()`** (y rutas relacionadas: viewer, manifests, navigation bundle).

---

## 3. Incidente documentado (seed de DB sin regenerar artefactos)

### Qué se hizo

- Se añadió seed ORM homogéneo (422 filas) vía `bootstrapEmptyRealmDatabase` / `ensureAlexandriaRealmSeededIfEmpty`.
- Se generó solo **`alexandria.db`** (p. ej. script `LibraryBuild/tool/seed_default_realm_db.dart`).
- Se corrigió **`ensureLibrarySchema`**: faltaba la columna **`title`** en DB nueva; los `UPDATE … title` fallaban hasta añadir `ALTER TABLE … ADD COLUMN title`.

### Errores / lecciones

1. **DB sola no alimenta a GK.** Sin **`runLibraryBuild()`**, no hay `snapshot/current.json` (ni viewer/manifests coherentes con el estado actual).
2. **Orden de migración:** `bootstrapEmptyRealmDatabase` llama `ensureLibrarySchema`; si `title` no existía, fallaba en una DB creada solo con `CREATE TABLE entries (key, parentKey, seq)`. *Corregido en código:* `ensureLibrarySchema` ahora asegura `title` antes de los `UPDATE`.
3. **Copiar solo `alexandria.db` desde un backup** sin la carpeta `snapshot/` (y sin volver a ejecutar LB) reproduce el mismo síntoma.
4. **Reset nuclear** (`performAlexandriaNuclearDataResetSync`) recrea DB con seed; el snapshot se regenera al abrir LB si faltaba (ver §7).

---

## 4. Recomendación (fix vs copia)

- **Preferir el arreglo en sitio (§5 Opción B)** cuando la DB ya es la homogénea correcta y solo faltaban artefactos derivados: es el fallo que causó el incidente (DB sin snapshot). Con `ensureGatekeeperSnapshotArtifactsSync` + un **Refresh** manual si hiciera falta, suele bastar.
- **Preferir copia completa (§5 Opción A)** cuando necesitáis también **assets** en disco, múltiples realms, o no confiáis en el estado del árbol `data/realms/…` (mezcla de legado plano `data/` vs per-realm).

---

## 5. Dos caminos de recuperación

### Opción A — Restaurar desde copia conocida (`data - copia` o backup)

1. Copiar al menos `data/realms/<realm>/` **completo** para el realm activo: `alexandria.db`, `snapshot/`, `viewer/`, `bridge/`, `manifests/`, `navigation/` según lo que ya teníais funcionando.
2. Alinear `data/active_realm.txt` con esa carpeta.
3. Arrancar LB y, si algo quedó inconsistente, **Refrescar** (dispara `runLibraryBuild()`).

**Cuándo preferir A:** copia íntegra reciente; pérdida de confianza en el estado actual; muchos assets en disco.

### Opción B — Arreglar en sitio (repo actual)

1. Asegurar `data/active_realm.txt` → realm correcto (p. ej. `default`).
2. Abrir **LibraryBuild** y usar **regenerar snapshot / lista** (o equivalente que llame `runLibraryBuild()`), **o** confiar en el **sync automático al arrancar** si está implementado: si falta `snapshot/current.json`, LB ejecuta `runLibraryBuild()` una vez.
3. Verificar que exista:  
   `data/realms/<active>/snapshot/current.json`

**Cuándo preferir B:** la DB ya es la homogénea correcta y solo faltan artefactos derivados; evita mezclar copias viejas.

---

## 7. Comportamiento en código (implementado)

- **`ensureGatekeeperSnapshotArtifactsSync()`** (`library_build.dart`): si no existe `snapshot/current.json` del realm activo, llama **`runLibraryBuild()`** una vez.
- Llamado desde **LibraryBuild** tras abrir la DB y **`ensureDualBridgeDefaults`**: arranque, cambio de realm, y tras **reset nuclear** (éxito y error de apertura).

---

## 8. Checklist rápido de diagnóstico

| Comprobar | Ruta / acción |
|-----------|----------------|
| Mismo realm | `data/active_realm.txt` = segmento bajo `data/realms/` |
| DB presente | `data/realms/<realm>/alexandria.db` |
| Snapshot para GK | `data/realms/<realm>/snapshot/current.json` existe y es reciente tras un cambio en LB |
| Bridge mínimo | `bridge/context_key.txt`, `bridge/focus_key.txt` (LB: `ensureDualBridgeDefaults`) |
| Refresco GK | `bridge/refresh_now.txt` tras build (LB ya lo escribe en el flujo de build) |

---

## Realm seed (DB limpia repetible)

- **`applyRealmSeedSanitization` / `pruneRealmAssetFoldersNotInEntries`** (`library_build.dart`): vacía `body_text`, métricas en columnas de `entries`, tablas de eventos/review, Parcour Review, `assets` (SQL), `pao_standard`; reconstruye FTS; poda carpetas bajo `assets/` que no sean un `key` de `entries` (whitelist `pao`).
- **Script:** `LibraryBuild/tool/apply_realm_seed.dart` — aplica lo anterior en el realm activo, ejecuta `runLibraryBuild()`, copia `alexandria.db` a **`data/realm_seed/alexandria.db`** como **clon repetible** (misma estructura ORM, sin datos de usuario).
- **Recomendación:** versionar `data/realm_seed/alexandria.db` en git (fichero pequeño) o documentar cómo regenerarlo con el script tras cambios de esquema.

---

## Historial

| Versión | Nota |
|---------|------|
| 1.0 | Incidente seed DB vs snapshot GK; opciones A/B de recuperación; checklist. |
| 1.1 | Realm seed: script + ruta `data/realm_seed/alexandria.db`. |
