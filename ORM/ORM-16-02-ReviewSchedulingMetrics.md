# ORM-16-02 — Métricas de repaso y scheduling (Recall, Fibonacci, Parcour)

**Índice serie:** [ORM-16-00-Index](./ORM-16-00-Index.md)

**Alineación ORM-15V4-A15 §1:** existen **dos motores** — *Recall (rápido)* y *Fibonacci / estudio estructurado* — con soporte de datos **separado**. Este documento describe **cómo está implementado hoy** en LibraryBuild + SQLite y qué superficies las consumen. **No** unificar métricas ni etiquetas sin decisión explícita de ORM.

**Referencia de código principal:** `LibraryBuild/lib/library_build.dart` (`recordRecallReview`, columnas `entries`, `review_events`), `locus_review_metrics.dart`, `parcour_review.dart`, `metrics_recall_page.dart`, `main.dart`, `fts_object_search.dart`; bridge `alexandria_paths.dart` (`parcour_review_summary.json`).

---

## 1. Principio: dos vías, dos familias de tablas

| Motor | Rol | Persistencia principal | Umbral / notas |
|-------|-----|-------------------------|----------------|
| **Recall (rápido)** | Grades tipo SM-2 liviano en LB; botones Again/Hard/Good/Easy | Columnas en `entries` + historial `review_events` | Grade 0–3; solo `cognitiveRole = 'object'` |
| **Fibonacci (estructurado)** | Sesiones con % de acierto por bloques; intervalos en días (sucesión Fib) | `locus_review_state`, `locus_review_events` | Pass de sesión típico `pct ≥ 0.8`; mínimo de bloques evaluables (p. ej. ≥ 3) para mutar estado |

**Parcour agregado (tercer eje):** repaso **a nivel parcour** con ratings por locus (good/medium/fail), estado `parcour_review_*` y sesiones registradas; sirve para **Parcour Study** y ordenación/tiers, distinto del recall por grade en `entries`.

---

## 2. Recall — columnas en `entries`

Campos usados por UI y agregados (entre otros):

- **Temporal:** `last_reviewed_at`, `next_review_at`
- **Conteos:** `review_count`, `success_count`, `failure_count`, `last_review_grade`
- **Modelo heurístico:** `memory_strength`, `stability_days`, `recall_score`

**Escritura:** `recordRecallReview(db, entryKey, grade)` — actualiza fila y append en `review_events` (grade, estabilidades/fuerzas antes-después, éxito binario).

**Lectura / agregación:** `computeRecallStatsForParent`, `computeRecallStatsForSubtree` — cuentas `due` / `new` / `total` según `next_review_at` y subárbol recursivo.

**UI:** lista en `main.dart` (métricas por entrada, botones de grade), página **Recall metrics** (`metrics_recall_page.dart`), export CSV; **Node card reader** (`node_card_reader_page.dart`) muestra columnas crudas.

---

## 3. Fibonacci por locus — `locus_review_*`

- **`locus_review_state`:** `entry_key`, `fib_index` (índice en tabla de días), `last_ok_at`, `next_due_at`, `last_session_pct`
- **`locus_review_events`:** trazas de sesión (`rating` PASS/FAIL/INSUFFICIENT_DATA, `pct`, índices fib antes/después, `due_after`, `created_at`)

**Reglas (implementación):** `applyLocusReviewOutcome` — si no hay suficientes bloques evaluables, se registra evento sin mutar estado; si hay datos, pass según `currentParcourPassNormSync()` avanza índice Fibonacci (hasta tope), si no retrocede; intervalo en días = valor en `kParcourFibDays` (`parcour_review.dart`, compartido con parcour y Match cards; ver ORM-16-09 §4 para la lista literal).

**Agregación UI:** `getLocusStatsForParent`, `summarizeLocusScheduleForSubtree`, `formatLocusScheduleSummaryLine` — barra “Fib · última / próximo” separada del recall.

---

## 4. Parcour — `parcour_review_*` y bridge

**Tablas:** `parcour_review_state`, `parcour_review_sessions`, `parcour_review_session_loci` (ver `ensureParcourReviewSchema`).

**Sesión:** `applyParcourReviewSession` — normaliza ratings good/medium/fail, umbral de pass agregado (p. ej. norm ≥ 0.8), avance de índice Fibonacci **a nivel parcour** (misma familia de días que locus), trazabilidad en sesiones.

**Bridge (GK solo lectura):** `writeParcourReviewBridgeSummary` → `data/realms/<realm>/bridge/parcour_review_summary.json` — resumen por parcour (`fibIndex`, `nextDueAt`, conteos good/medium/fail, `sessionPct`, etc.). **GateKeeper** puede usarlo para color/drill-down sin tocar DB.

---

## 5. Búsqueda y ranking (FTS)

`fts_object_search.dart` mezcla señales (p. ej. `recall_score`, `review_count`, fechas) en un **score de relevancia** para resultados; es ranking UX, **no** redefine el significado clínico de recall vs Fibonacci.

---

## 6. GateKeeper y “métricas”

- GK **no** calcula scheduling; puede **leer** JSON de viewer y `parcour_review_summary.json` según implementación actual.
- Viewer de contenido: payload generado por LB (`library_build.dart` — rutas bajo `data/viewer/`); métricas recall visibles en el payload si el builder las incluye (criterio A15: GK no accede a SQLite).

---

## 7. USING / KEEP / SEEK (ORM-15V4 §5)

Siguen siendo **intenciones de producto**; tiers/ordenación en código de parcour (`parcour_review` sort tiers) se acercan conceptualmente — cualquier columna obligatoria en DB requeriría extensión explícita del ORM.

---

## 8. Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Primera versión ORM-16-02; inventario según código LibraryBuild 2026. |
