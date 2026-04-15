# ORM-16 — Índice (contrato actual)

**Estado:** la familia **ORM-16** es el conjunto de documentos **más actuales** para implementación y revisión de PRs en Alexandria. Complementa y, donde choca con detalle desactualizado, **toma precedencia operativa** sobre el texto largo de ORM-15V2/V3.

**Relación con ORM-15V3 / ORM-15V4:**

| Artefacto | Rol |
|-----------|-----|
| **ORM-15V3** | Contrato largo (layout, maze como propiedad de GK, invariantes snapshot, etc.). Sigue siendo referencia histórica y de principios. |
| **ORM-15V4-A15.md** | Compañero operativo A15 (bridge, dos motores de repaso, alcance). **ORM-16** lo **materializa** en archivos por tema con trazabilidad a código. |

**No se reescribe** ORM-15V* en bloque: ORM-16 enlaza y acota.

**Hacia “Alexandria 16”:** la serie ORM-16 es la base documental para una **renovación de producto** posterior (mejoras y alineación amplia). Este índice y los `ORM-16-NN-*` describen el **contrato y lo implementado hoy**; no sustituyen por sí solos un plan de migración de código hasta que exista un hito explícito.

---

## Documentos ORM-16 (por subíndice)

| Doc | Tema |
|-----|------|
| **ORM-16-00-Index** | Este índice. |
| **ORM-16-01-SpatialMazeCollages** | GK: layout MAZE, collages en pared, `_mazeExpandedFramePositions`. |
| **ORM-16-02-ReviewSchedulingMetrics** | LB/SQLite: recall rápido, Fibonacci por locus, repaso por parcour, tablas, bridge, UI y separación de motores. |
| **ORM-16-03-RealmCastleCompletion** | Reglas de producto “Castle” / completitud (referencia a capas; no es esquema SQL). |
| **ORM-16-04-CastleActiveRidiculousStory** | Activo Castle = `ridiculous_story`; good desde Parcour Review; hijos directos; N/A sin sesión. |
| **ORM-16-05-LB-GK-DataRecovery** | Recuperación LB↔GK: snapshot vs DB, incidente seed sin `runLibraryBuild`, checklist y opciones restore vs fix-in-place. |
| **ORM-16-06-MatchCardsLb** | Juego Match cards solo en LB: tablas `lb_match_pairs` / `lb_match_pair_fsrs_state`, `route_key` reservado, assets `lb_match_cards/`; sin GK. |
| **ORM-16-07-LocusBodyJsonViewer** | Contrato `body_text` como JSON de bloques (`p`, `img`, `link`, `card`, …) y viewer GK; distinción vs ORM-16-06. |
| **ORM-16-08-MatchCardsModel-en** | Match cards: modelo (lemma / transliteration / gloss), revisión vs FSRS, ejemplo léxico (EN). |

---

## Convención de nombres

- **`ORM-16-NN-Descriptivo.md`** — `NN` ordenable (00, 01, 02…); descriptivo en *PascalCase* corto en inglés para nombres de archivo estables.

---

## Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Creación de la serie ORM-16; migración del doc MAZE a 16-01; nuevos 02 y 03. |
| 1.1 | ORM-16-04 Castle + ridiculous_story. |
| 1.2 | ORM-16-05 recuperación datos LB/GK (snapshot `current.json`). |
| 1.3 | ORM-16-05 Realm seed (`data/realm_seed/alexandria.db` + script). |
| 1.4 | ORM-16-06 Match cards (LB); ORM-16-07 bloques JSON locus + viewer; nota “Alexandria 16” en índice. |
| 1.5 | ORM-16-08 modelo Match cards (EN); columnas `transliteration` / `gloss`. |
