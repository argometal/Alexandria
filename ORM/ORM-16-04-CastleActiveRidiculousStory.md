# ORM-16-04 — Castle: activo por `ridiculous_story` y completitud (LB)

**Índice serie:** [ORM-16-00-Index](./ORM-16-00-Index.md)

**Relación:** complementa [ORM-16-03](./ORM-16-03-RealmCastleCompletion.md) y **LAYERS** con reglas **selladas** para código en LibraryBuild. Parcour Review **no** comparte aún la misma definición de “activo” (sigue “evaluable” = hint/place/ridiculous en [study_utils]).

---

## 1. Activo Castle (denominador)

- **Activo Castle** = el **objeto (locus)** tiene en `body_text` **al menos un** bloque párrafo con `textKind` **`ridiculous_story`** (tras el mismo `parseBody` / normalización que el editor).
- Sin `ridiculous_story` → el locus **no** es activo Castle (concepto `evaluation_incomplete` para esta vía; **sin columna DB** en v1).
- `hint` y `place` **solos** → **no** activos Castle.

## 2. Fuente de “good” para métrica Castle

- **Good** = el **último** resultado de **Parcour Review** para ese `locus_key` **dentro de ese parcour** (todas las sesiones cuyo `parcour_key` coincide).
- **Criterio algorítmico (sellado):** se unen `parcour_review_session_loci` con `parcour_review_sessions`, filtro `parcour_key = parcour`, orden **`sessions.id` DESC**. Se recorre en ese orden y, **por cada `locus_key`, se conserva solo la primera aparición**. Eso equivale al rating de la **sesión más reciente en la que ese locus participó** — no al rating “solo de la última sesión del parcour” si en esa sesión el locus no tuvo fila (evita reinterpretaciones futuras).
- Criterio de string: resultado canónico **`good`** (mismo que `locusRatingLabel` / filas guardadas).

## 3. Completitud Castle (ámbito)

- **Solo hijos directos** del parcour (`parentKey = parcourKey`, `cognitiveRole = 'object'`). **Sin** subárbol recursivo.

## 4. Porcentaje y N/A

- **Numerador:** loci Castle-activos cuyo último rating en ese parcour es `good`.
- **Denominador:** loci Castle-activos (hijos directos).
- Si **no hay ninguna sesión** Parcour Review para ese parcour → mostrar **N/A** (no **0%**).
- Si **denominador 0** (ningún hijo con `ridiculous_story`) → **N/A** (nada que medir en esta vía).

## 5. GateKeeper

- **Solo lectura** de artefactos que LB genere (fase posterior); sin SQLite en GK.

## 6. UI (coexistencia con Parcour Review)

- **Castle** y **Parcour Review** son líneas **distintas**: Parcour Review = desempeño/scheduling del flujo de sesión; Castle = completitud sobre activos `ridiculous_story`. No sustituir una por la otra; prefijos claros (p. ej. `Parcour ·` vs `Castle:`).

## 7. Estudio (producto; reglas no implementadas en código aún)

- **Place + hero:** el estudio debe anclar la pregunta en **dónde** (place) sobre la imagen (hero), no en hint como foco principal.
- **Hint:** puede mostrarse **tras un clic** opcional; si se usa, el **grading máximo efectivo es medium** aunque el usuario pulse good (regla de producto para futura pantalla Study).
- **Lista LB:** doble clic en **object** → **visor de contenido** (`NodeCardReaderPage`); semáforo = último resultado Parcour Review por locus (good/medium/fail).

---

## Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Fase 0 sellada; alineada a implementación `isCastleActiveLocus` + `computeCastleCompletionForParcour`. |
| 1.1 | §2: criterio explícito “última sesión en la que el locus participó”; §6 UI coexistencia. |
| 1.2 | §7 place+hero vs hint; visor object + semáforo LB. |
