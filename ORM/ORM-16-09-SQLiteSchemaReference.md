# ORM-16-09 — Referencia SQLite (realm activo)

**Índice serie:** [ORM-16-00-Index](./ORM-16-00-Index.md)

**Propósito:** una sola hoja de **verdad operativa** para tablas y columnas que **LibraryBuild** crea o migra en `data/realms/<realm>/alexandria.db`. Cualquier otro doc ORM que contradiga este archivo debe actualizarse o marcarse como histórico.

**Código fuente de verdad:** `LibraryBuild/lib/library_build.dart` (`ensureLibrarySchema`, `bootstrapEmptyRealmDatabase`, `_ensure*`), `LibraryBuild/lib/parcour_review.dart` (`ensureParcourReviewSchema`), stores PAO / poker / match cards en los mismos imports que `ensureLibrarySchema`.

---

## 1. Árbol homogéneo (claves fijas en semilla LB)

Implementación actual de `_insertHomogeneousSkeletonIfNeeded` / comentarios en `library_build.dart`:

| Rol | `key` | `parentKey` | `cognitiveRole` |
|-----|--------|-------------|-----------------|
| Realm | `ROOT` | `NULL` | `realm` |
| Hub parcours | `PARCOUR_MAIN` | `ROOT` | `parcour` |
| Parcour | `L1` … `L20` | `PARCOUR_MAIN` | `parcour` |
| Objeto | `Lk_O01` … `Lk_O20` | `Lk` | `object` |

**Conteo:** 1 + 1 + 20 + 400 = **422** filas `entries` en el modelo homogéneo descrito en código (el doc [LAYERS](./LAYERS_REALM_PARCOUR_OBJECT.md) habla a veces de `R1`/`Pk` como vocabulario objetivo; **hasta migración explícita**, la semilla LB usa `ROOT` / `PARCOUR_MAIN` / `L*`).

---

## 2. Tabla `entries`

**Creación mínima** (`bootstrapEmptyRealmDatabase`): `key`, `parentKey`, `seq`.

**Columnas añadidas / rellenadas por** `ensureLibrarySchema` (nombres exactos):

| Columna | Uso breve |
|---------|-----------|
| `title` | Título UI |
| `body_text` | JSON de bloques del locus (ver ORM-16-07) |
| `cognitiveRole` | `realm` \| `parcour` \| `object` (`kCognitiveRoles` en código) |
| `last_reviewed_at`, `next_review_at` | Motor **recall** rápido |
| `review_count`, `success_count`, `failure_count`, `last_review_grade` | Recall |
| `memory_strength`, `stability_days`, `recall_score` | Heurística recall (objetos) |
| `spatial_turn` | Metadato espacial (string) |
| `place_recall_active` | Flag entero (place recall) |

**FTS:** tabla virtual `entries_fts` (rebuild vía `rebuildEntriesFts5`); ver `fts_object_search.dart`.

---

## 3. Tabla `review_events` (recall)

Columnas en `CREATE` de `library_build.dart`:

- `id`, `entryKey`, `reviewed_at`, `grade` (0 Again … 3 Easy)
- `previous_stability_days`, `new_stability_days`
- `previous_memory_strength`, `new_memory_strength`
- `success`

**Escritura:** `recordRecallReview`.

---

## 4. Fibonacci por locus — `locus_review_state` / `locus_review_events`

**`locus_review_state`:** `entry_key` PK, `fib_index`, `last_ok_at`, `next_due_at`, `last_session_pct`.

**`locus_review_events`:** `id`, `locus_key`, `rating`, `pct`, `fib_index_before`, `fib_index_after`, `due_after`, `created_at`.

**Intervalos en días:** un solo vector en código, `kParcourFibDays` en `parcour_review.dart` (compartido con parcour agregado y Match cards):

`1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377`

Índice `fib_index` ∈ [0, length−1]; el valor en días hasta el siguiente `next_due_at` tras sesión válida es `kParcourFibDays[fib_index]` tras aplicar reglas en `applyLocusReviewOutcome`.

**Umbral de “pass” de sesión estructurada:** no es fijo 0.8 en todas las instalaciones: `currentParcourPassNormSync()` lee `bridge/memory_athlete_mode.txt` (realm activo) y devuelve **1.0** (atleta) o **0.8** (estándar). Misma lectura para parcour agregado.

**Lógica:** `applyLocusReviewOutcome` en `locus_review_metrics.dart` (mínimo de bloques evaluables, eventos `INSUFFICIENT_DATA` sin mutar estado).

---

## 5. Parcour agregado — `parcour_review_*`

Definición en `ensureParcourReviewSchema` (`parcour_review.dart`):

**`parcour_review_state`:**  
`parcour_key` PK, `fib_index`, `last_ok_at`, `next_due_at`, `last_score_raw`, `last_score_norm`, `evaluated_count`, `last_approved_fib`, `last_session_at`, `stable_at`.

**`parcour_review_sessions`:**  
`id`, `parcour_key`, `session_at`, `score_raw`, `score_norm`, `evaluated_count`, `passed`, `fib_before`, `fib_after`, `due_after`.

**`parcour_review_session_loci`:**  
`id`, `session_id`, `locus_key`, `result` (`good`/`medium`/`fail`), `value`, `was_reviewed`.

**Lógica:** `applyParcourReviewSession` — usa la misma lista `kParcourFibDays` y reglas de bootstrap / estable / paso fuerte documentadas en comentarios del archivo.

**Bridge (GK lectura):** `AlexandriaPaths.parcourReviewSummaryPath` → `bridge/parcour_review_summary.json` vía `writeParcourReviewBridgeSummary`.

---

## 6. Match cards, Go, PAO, poker

- **Match cards:** `lb_match_pairs`, `lb_match_pair_fsrs_state`, `lb_match_decks` — detalle ORM-16-06 / ORM-16-08. `fib_index` + `due_at` siguen el mismo eje `kParcourFibDays`.
- **Go:** `lb_go_problem_progress`.
- **PAO:** tablas en `pao_*` stores (ver exports en `library_build.dart`).
- **Poker memory:** `ensurePokerMemorySchema`.

---

## 7. Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Creación: alineación a `library_build.dart` + `parcour_review.dart` + `kParcourFibDays` unificado (incl. 377). |
