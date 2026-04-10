# ORM-16 — Índice (contrato actual)

**Estado:** la familia **ORM-16** es el conjunto de documentos **más actuales** para implementación y revisión de PRs en Alexandria. Complementa y, donde choca con detalle desactualizado, **toma precedencia operativa** sobre el texto largo de ORM-15V2/V3.

**Relación con ORM-15V3 / ORM-15V4:**

| Artefacto | Rol |
|-----------|-----|
| **ORM-15V3** | Contrato largo (layout, maze como propiedad de GK, invariantes snapshot, etc.). Sigue siendo referencia histórica y de principios. |
| **ORM-15V4-A15.md** | Compañero operativo A15 (bridge, dos motores de repaso, alcance). **ORM-16** lo **materializa** en archivos por tema con trazabilidad a código. |

**No se reescribe** ORM-15V* en bloque: ORM-16 enlaza y acota.

---

## Documentos ORM-16 (por subíndice)

| Doc | Tema |
|-----|------|
| **ORM-16-00-Index** | Este índice. |
| **ORM-16-01-SpatialMazeCollages** | GK: layout MAZE, collages en pared, `_mazeExpandedFramePositions`. |
| **ORM-16-02-ReviewSchedulingMetrics** | LB/SQLite: recall rápido, Fibonacci por locus, repaso por parcour, tablas, bridge, UI y separación de motores. |
| **ORM-16-03-RealmCastleCompletion** | Reglas de producto “Castle” / completitud (referencia a capas; no es esquema SQL). |
| **ORM-16-04-CastleActiveRidiculousStory** | Activo Castle = `ridiculous_story`; good desde Parcour Review; hijos directos; N/A sin sesión. |

---

## Convención de nombres

- **`ORM-16-NN-Descriptivo.md`** — `NN` ordenable (00, 01, 02…); descriptivo en *PascalCase* corto en inglés para nombres de archivo estables.

---

## Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Creación de la serie ORM-16; migración del doc MAZE a 16-01; nuevos 02 y 03. |
| 1.1 | ORM-16-04 Castle + ridiculous_story. |
