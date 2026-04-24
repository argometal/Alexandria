# ORM-16-06 — Match cards (Library Build only)

**Índice serie:** [ORM-16-00-Index](./ORM-16-00-Index.md)

**Tipo:** contrato de datos y alcance para el **juego de emparejamiento** imagen ↔ pie de texto en **LibraryBuild** (Flutter + SQLite del realm activo). **No** forma parte del corredor espacial ni del snapshot de GateKeeper.

---

## 1. Relación con ORM-15V3 / ORM-15V4-A15

| Referencia | Cómo encaja |
|------------|-------------|
| **ORM-15V3** | GK posee layout MAZE; snapshot y viewer JSON son lectura de contenido. Las tablas aquí descritas **no** alimentan snapshot ni `viewer/*.json` del pipeline A15 salvo decisión explícita futura. |
| **ORM-15V4-A15 §1** | Los **dos motores de repaso** (Recall en `entries` / Fibonacci en `locus_review_*`) siguen **independientes** del juego Match cards. La tabla `lb_match_pair_fsrs_state` guarda **métricas y scheduling propios del juego** (índice Fib + `due_at` + conteos), con el **mismo eje de días** que locus/parcour (`kParcourFibDays`); **no** escribe en `entries` ni en `locus_review_*`. Las columnas `stability` / `difficulty` / `elapsed_days` siguen sin uso (reserva FSRS-like). |
| **ORM-15V4-A15 §7** | Estudio estructurado por parcour vs objeto: Match cards es una **tercera superficie** (práctica de pares en LB); sigue fuera del alcance “Object structured study” del §7 hasta que el ORM lo una explícitamente. |

---

## 2. Alcance implementado

- **UI:** cajón LB → sección Match cards → mazos, lista de pares, alta (imagen + pie), borrado, sesión (hasta 4 pares por sesión por defecto) con **priorización** por `fib_index` bajo / `due_at` antiguo / más `fail_count`, luego barajado; **hoja de estadísticas** por par (`fib_index`, aciertos/fallos) en la sesión (`match_cards_session_page.dart`).
- **Persistencia:** SQLite en `alexandria.db` del realm activo (`ensureLibrarySchema` → `_ensureMatchCardsSchema`).
- **Archivos:** imágenes bajo `data/realms/<realm>/assets/lb_match_cards/` (nombre almacenado en columna `image_basename`).

**GateKeeper:** no lee estas tablas; no hay bridge dedicado.

---

## 3. Tablas

### 3.1 `lb_match_pairs`

| Columna | Tipo | Significado |
|---------|------|-------------|
| `id` | INTEGER PK | Identificador del par. |
| `image_basename` | TEXT NOT NULL | Nombre de archivo dentro de `assets/lb_match_cards/`. |
| `caption_text` | TEXT NOT NULL | Lema / palabra en **escritura nativa** (UTF-8). |
| `transliteration` | TEXT NULL | Transliteración / romanización opcional (p. ej. `koshka`). Migración: `ALTER` si la tabla era anterior. |
| `gloss` | TEXT NULL | Significado / traducción opcional (p. ej. `cat`). |
| `route_key` | TEXT NULL | **Reservado ORM:** `NULL` = pool global atendido por la UI actual. Valor futuro: asociar el par a una **ruta** (p. ej. clave de parcour o convención acordada) para repaso “mientras recorres” el espacio — **sin lógica implementada**. |
| `created_at` | TEXT NOT NULL | ISO-8601 UTC típico. |

**Modelo en inglés (tabla léxica):** ver **[ORM-16-08-MatchCardsModel-en.md](./ORM-16-08-MatchCardsModel-en.md)**.

**Regla de producto actual:** la lista y el juego filtran `route_key IS NULL` (pool LB).

### 3.2 `lb_match_pair_fsrs_state`

Estado **por par** tras sesiones de emparejamiento: scheduler **tipo Fibonacci** (mismo vector `kParcourFibDays` que ORM-16-02 / `parcour_review.dart`), no FSRS completo. Escritura: `lbRecordMatchPairOutcome` en `match_cards_store.dart` (acierto sube `fib_index`, fallo baja; actualiza `due_at`, `last_review_at`, `reps`, `pass_count`, `fail_count`).

| Columna | Tipo | Notas |
|---------|------|--------|
| `pair_id` | INTEGER PK | Coincide con `lb_match_pairs.id`. |
| `fib_index` | INTEGER NOT NULL DEFAULT 0 | Índice en `kParcourFibDays` (intervalo hasta próximo `due_at`). |
| `due_at`, `last_review_at` | TEXT NULL | ISO-8601 UTC; `due_at` alimenta ordenación de sesión. |
| `reps` | INTEGER NOT NULL DEFAULT 0 | Sesiones de juego registradas (incremento por outcome). |
| `pass_count`, `fail_count` | INTEGER NOT NULL DEFAULT 0 | Contadores por acierto / fallo en el tablero. |
| `stability`, `difficulty`, `elapsed_days` | REAL NULL | Sin lógica aún (reserva nombre FSRS). |

**Invariante ORM:** no mezclar el significado de estas columnas con `entries.recall_score` ni `locus_review_state` sin trazabilidad en revisión de ORM.

---

## 4. Evolución prevista (no obligatoria en código hasta acuerdo)

1. **Ruta:** rellenar `route_key` y filtrar sesiones por contexto espacial o de navegación — probablemente coordinado con bridge/`context_key` solo en LB primero.
2. **FSRS “de verdad”:** usar o sustituir las columnas `stability` / `difficulty` / `elapsed_days` con un modelo distinto del Fib actual (hoy no se leen).

---

## 5. Referencia de código

- Esquema: `LibraryBuild/lib/library_build.dart` — `_ensureMatchCardsSchema`, `ensureLibrarySchema`.
- Acceso datos: `LibraryBuild/lib/match_cards/match_cards_store.dart`.
- UI: `LibraryBuild/lib/match_cards/match_cards_page.dart`, `match_cards_session_page.dart`.
- Entrada menú: `LibraryBuild/lib/main.dart` (cajón).

---

## 6. Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Primera versión ORM-16-06; inventario según implementación LibraryBuild + tablas match cards. |
| 1.1 | Alineación: `lb_match_pair_fsrs_state` con scheduler Fib + conteos en uso; UI de stats en sesión; priorización de pares; FSRS legacy aún sin lógica. |
