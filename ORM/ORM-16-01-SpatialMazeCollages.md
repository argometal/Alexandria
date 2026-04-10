# ORM-16-01 — Espacio: MAZE, collages y posición de marcos

**Índice serie:** [ORM-16-00-Index](./ORM-16-00-Index.md)

**Tipo:** contrato de implementación alineado con ORM-15V3 (layout propiedad de **GK**; snapshot sin coordenadas). Este archivo detalla el comportamiento **actual** en código.

**Código de referencia:** `GateKeeper/Spawner.cs`.

---

## 1. Problema resuelto

En **CORRIDOR_Z**, el espaciado entre marcos se recalcula con `RebuildCorridorZLayout` usando `ComputeSegmentGap(n)` según el número de grupos collage del locus.

En **MAZE**, las posiciones nominales venían de un grafo con aristas de longitud fija (`MazeStraightEdgeMeters`, salida tras giro `MazeOutgoingAfterTurnMeters`, buffer `MazeFrameTurnBufferMeters`). Esa longitud podía ser **menor** que el tramo mínimo que exige `TryComputePanelBounds` para varios collages → solo cabía el primer panel (`PANEL_TRIM_MAZE`).

---

## 2. Solución (fuente única de verdad espacial en MAZE)

1. **Campo:** `_mazeExpandedFramePositions` — `Vector3[20]`, posición de marco **tras** expandir aristas.

2. **Cálculo:** `RebuildMazeExpandedFramePositions(keysBySeq)`  
   - Marco `0`: coincide con `GetPositionFromSeq(0)` (grafo nominal; el tramo previo al marco 0 sigue anclado por `ComputeSegmentGap` hacia atrás en `BuildAllMazeSegments`).  
   - Marco `dest ≥ 1`:  
     - **Arista recta** (`spatialTurn` en el borde anterior ≠ left/right):  
       `along = max(ComputeSegmentGap(collages del locus dest), MazeStraightEdgeMeters)`  
       en dirección `GetPersistentDirection(dest - 1)`.  
     - **Arista con giro** en el borde anterior: esquina = `pos[dest-1] + incoming * MazeFrameTurnBufferMeters` (mismo `incoming` que el código de segmentos); luego  
       `along = max(ComputeSegmentGap(collages del locus dest), MazeOutgoingAfterTurnMeters)`  
       en dirección saliente `GetPersistentDirection(dest - 1)`.  
   - La expansión es **acumulativa**: un tramo largo desplaza todos los marcos siguientes a lo largo del recorrido.

3. **Consumidores en MAZE** (no usar `GetPositionFromSeq` para posición de marco cuando el array está construido):  
   - Colocación de `FramesContainer` en `ApplyCorridorGeometryAfterSnapshot`.  
   - `BuildAllMazeSegments` — `pA` / `pB` desde `_mazeExpandedFramePositions`.  
   - `TryRestoreCameraAfterSnapshot` — posición X/Z del rig alineada al marco.  
   - `GetSegmentFrameFromSeq` — coherencia si en el futuro se usa para espacio.

4. **CORRIDOR_Z:** sin cambio; `_mazeExpandedFramePositions = null`.

5. **Invariantes no tocados:**  
   - `GetPositionFromSeq` sigue definiendo el **grafo nominal** (giros, pasos).  
   - `TryComputePanelBounds`, `BuildPanelsForTramoMaze`, `ComputeSegmentGap` — mismas fórmulas.  
   - Geometría de giro en segmentos (buffer + segunda pierna con collages) — misma topología; solo cambian los puntos finales de marco cuando hace falta más longitud.

---

## 3. Regla de producto

> En MAZE, la distancia recorrida entre el marco `dest-1` y el marco `dest` a lo largo de la polilínea del laberinto debe ser al menos la que exige el **contenido collage** del locus `dest`, sin acortar por debajo de la longitud nominal de arista del maze cuando el contenido lo permite.

---

## 4. Validación manual sugerida

- Locus con 2–3 collages en tramo recto MAZE: todos visibles.  
- Tras un giro: collages solo en la pierna **posterior** a la esquina (como antes).  
- Cámara al restaurar seq: alineada con marco expandido.  
- Parcour sin giros: comportamiento CORRIDOR_Z idéntico al anterior.

---

## 5. Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Documento inicial como `ORM-16-MazeCollageLayout.md`. |
| 1.1 | Renombrado a **ORM-16-01**; enlace al índice ORM-16-00. |
