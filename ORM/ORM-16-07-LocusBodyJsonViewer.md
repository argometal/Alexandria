# ORM-16-07 — `body_text` JSON: bloques de locus y viewer (LB → GK)

**Índice serie:** [ORM-16-00-Index](./ORM-16-00-Index.md)

**Tipo:** contrato de **contenido serializado** en `entries.body_text` (JSON array de bloques) y su consumo en el **viewer** de GateKeeper leyendo `data/realms/<realm>/viewer/<key>.json` (sin SQLite en GK). Alineado con el espíritu **ORM-15V3** (viewer como lectura de artefactos; GK sin DB).

**No confundir** con **ORM-16-06** (`lb_match_pairs`): allí es un **juego** con tablas propias; aquí los bloques viven **dentro del texto del locus** y viajan en el JSON del viewer.

---

## 1. Relación con ORM-15V3 / ORM-15V4

| Referencia | Cómo encaja |
|------------|-------------|
| **ORM-15V3** | Cuerpo del nodo como lista de bloques; assets bajo `assets/<entryKey>/`; foco del viewer por `focus_key` (bridge). |
| **ORM-15V4-A15 §3** | `context_key` + `focus_key`: los bloques `link` / `warp` / caras navegables del bloque `card` solicitan cambio de **foco** sin redefinir el layout MAZE. |

---

## 2. Formato

- **Raíz:** array JSON (`[]`).
- **Elemento:** objeto con `type` (o legacy `t`). Otros campos según tipo.
- **Parseo canónico (LB):** `parseBody` en `LibraryBuild/lib/library_build.dart` — normaliza tipos y `textKind` en párrafos.

---

## 3. Tipos reconocidos en implementación actual

| `type` | Campos principales | Uso |
|--------|---------------------|-----|
| `p` | `text`, `textKind` (`text`, `hint`, `place`, `ridiculous_story`, …) | Párrafo; hint/place/story como variantes de estudio. |
| `img` | `src`, `role` (`content` \| `hero` \| `collage`) | Imagen; hero/collage afectan snapshot/GK según builder. |
| `link` | `key`, `text` | Enlace a otra entrada (KEY); viewer emite navegación de foco. |
| `audio` | `src` | Referencia a fichero bajo assets (GK muestra estado; reproducción según implementación). |
| `warp` | `key`, `text` | Navegación de foco presentada como warp en viewer. |
| `tag` | `text` | Etiqueta visual. |
| `card` | `word`, `image` (o `src`), `phonetic`?, `audio`?, `related_to`? (array de KEY) | **Bloque de contenido** tipo ficha: palabra, ilustración, opcionales; `related_to` navega foco a otras KEY. **No** es la tabla `lb_match_pairs`. |

Los tipos desconocidos o legacy se pliegan a `p` con `textKind` inferido cuando aplica.

---

## 4. Assets

Ficheros referenciados por `src` / `image` / `audio` / `phonetic` se resuelven típicamente contra `data/realms/<realm>/assets/<entryKey>/` (convención compartida LB/GK).

---

## 5. GateKeeper

- **ViewerService** interpreta tipos anteriores para pintar el panel (imágenes, enlaces, bloque `card`, etc.).
- **RealmController** mantiene pila de foco para “volver” tras navegación por enlaces / relacionados del viewer (criterio operativo A15; no sustituye `context_key` jerárquico).

---

## 6. Referencia de código

- Parseo / export viewer: `LibraryBuild/lib/library_build.dart` (`parseBody`, `buildViewerForKey`, etc.).
- Editor: `LibraryBuild/lib/locus_editor.dart`.
- Viewer: `GateKeeper/ViewerService.cs`.

---

## 7. Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Primera versión ORM-16-07; inventario de tipos según `parseBody` + viewer. |
