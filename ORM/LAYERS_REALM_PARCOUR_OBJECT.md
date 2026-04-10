# ORM layers: Realm → Parcour → Object (reconstruction anchor)

**Purpose:** Single place to rebuild mental model after a git revert or new contributor session.  
**Scope:** Data model + bridge + GK snapshot semantics. (ORM-15V3 full text remains the long contract; this file is the **layer stack** summary.)

---

## The three layers (always this shape)

| Layer | Role in the tree | Typical `cognitiveRole` | In the corridor (GK) |
|-------|-------------------|---------------------------|-------------------------|
| **1. Realm** | Root of one “world” under which all parcours hang | `realm` | When `context_key` = realm key, **20 frames** show **parcour** children (not realm as a slot). |
| **2. Parcour** | One navigable run; holds exactly **20 object** children in the fixed model | `parcour` | When `context_key` = parcour key, **20 frames** show **object** children (loci). |
| **3. Object** | Leaf: one locus (content, review, assets) | `object` | Objects are **not** a `context_key` level in the usual flow: you stay in **parcour** `context_key` and move **focus_key** to the object while browsing. |

**Counts (homogeneous seed):** 1 realm + 20 parcours + 400 objects = **421** `entries` rows (20×20 objects).

---

## Realm vs Castle (product vocabulary — fixed)

These terms are **not** interchangeable.

| Term | Meaning |
|------|--------|
| **Realm (structural)** | The **full tree under one realm key** in the homogeneous model: **421 nodes** total in `entries` — 1 realm row + 20 parcours + 400 objects. **421 is the practical upper limit** of the developed allocation (capacity), **not** a requirement to author or “complete” every node. GK still shows **20 frames** per `context_key`; see table above. |
| **Castle (completion)** | A **completed phase** for that world, judged only on **frames that are *used*** in the authored experience (subset of nodes — how “used” is flagged belongs in **locus / product metrics**, e.g. in-scope for delivery). **Ridiculous-stories** (`historias ridículas`) completion is evaluated on that subset. **Castle qualifies** when **≥ 80%** of **used** frames are completed **at ridiculous-stories level** (not 80% of all 421). Example: **100** frames used, **80** of them completed to that bar → **80% of used** → qualifies. Knowledge may only need **100 frames or fewer**; the tree still caps at **421** as developed capacity. |

**Notes**

- **Unused** nodes (never part of the authored path) **do not** enter the castle denominator; otherwise small-scope worlds would be unfairly penalized.
- The exact definition of **“used frame”** (metadata column, rule, or export flag) must stay in sync with LB/GK and **locus_review** / story-completion fields — this file only fixes the **meaning** of Realm vs Castle.

---

## Keys (operational — as implemented in LibraryBuild / GateKeeper synthetic paths)

Canonical runtime pattern used in code and seed:

- **Realm:** `R1` (single realm in current seed).
- **Parcours:** `P1` … `P20` (children of `R1`).
- **Objects:** `Pk_O01` … `Pk_O20` under parcour `Pk` (two-digit suffix).

Legacy bridge/DB keys (`ROOT`, `C1`, `C1_Hhh`, `PARCOUR_*`, etc.) are **migrated** toward this pattern where applicable (`migrateLegacyBridgeKey` in LB).

**ORM-15V3 “castillo” block** (`C1`, `C1_H01`, …) is an **alternate naming vocabulary** in the long ORM doc. Code and seed in-repo have been aligned on **`R1` / `P*` / `P*_O*`** unless a deliberate product decision switches everything. If doc and code diverge, treat **code + DB seed** as operational truth until the ORM is updated in one pass.

---

## Database (`entries` table — conceptual)

- **`key`:** Primary identifier (realm / parcour / object).
- **`parentKey`:** Parent row’s `key`; realm row uses `NULL` (or empty, per schema).
- **`seq`:** Order among siblings **0…19** (fixed 20 slots per parent in the standard model).
- **`cognitiveRole`:** `realm` | `parcour` | `object` (metadata; snapshot building uses tree shape).

**Parent chain examples:**

- `R1` → parent `NULL`
- `P3` → parent `R1`
- `P3_O05` → parent `P3`

---

## Storage: one realm = one folder (LibraryBuild + GateKeeper)

- **Active realm** is stored in `data/active_realm.txt` (single line, id saneado; default `default`).
- **Data root for that realm:** `data/realms/<id>/` — contains `alexandria.db`, `bridge/`, `snapshot/`, `viewer/`, `assets/`, `navigation/`, `manifests/`, etc.
- **Migration:** on first LibraryBuild run, if legacy `data/alexandria.db` exists and `data/realms/default/alexandria.db` does not, LB copies the flat `data/` tree into `data/realms/default/`.
- **GK** resolves the same paths via `AlexandriaDataRoot.RealmDataRoot` (reads `active_realm.txt` each access). Restart GK after switching realms if files were generated while it was idle.
- **“Realm vacío” (nuevo en LB):** no significa solo `ROOT`. Significa **misma geometría de árbol** (hub `PARCOUR_MAIN` → `L1`…`L20` → 400 objetos) **sin datos de usuario**: `body_text` vacío, tablas de review/locus limpiadas, carpeta `assets/` nueva vacía. Las 420 “hojas” de contenido existen como filas; el techo `ROOT`/hub sigue el ORM.

---

## Bridge (filesystem, shared GK + LB — **per active realm**)

| File | Meaning |
|------|---------|
| **`context_key.txt`** | **Which level’s children** fill the 20 frames (snapshot parent): usually `R1` (see parcours) or `Pk` (see objects). |
| **`focus_key.txt`** | **Which entry** the **viewer** should describe (can be a parcour, an object, or empty). |
| **`current_seq.txt`** | Spatial slot index **0…19** (which frame along the corridor). |
| **`refresh_now.txt`** | Trigger: GK reloads snapshot / corridor after LB (or GK) updates. |

**Navigation intent:**

- **Enter (deeper level):** set `context_key` (and usually `focus_key`) to the child level you are entering; refresh.
- **Back (one level up):** set `context_key` and `focus_key` to **parent**; refresh.
- **Frame click (same level, different locus):** typically only **`focus_key`** changes; **`context_key`** stays the parcour when drilling within objects.

---

## Snapshot JSON (`data/snapshot/{context_key}.json`)

- Built from DB: **children of `parentKey = context_key`**, ordered by `seq`, mapped to **20 frames** (`seq` 0…19).
- GK **does not** query SQLite; it reads this JSON (or a **synthetic** equivalent for `R1` / `P*` when files are missing).

---

## GateKeeper (minimal)

- **Spawner** assigns each frame a **key** from the snapshot for current **`context_key`**.
- **ViewerService** reads **`viewer/{focus_key}.json`** (or `current.json` / offline synthesis) for panel text and **Back/Enter** targets (`parentKey`, `hasChildren`).

---

## LibraryBuild (minimal)

- Owns **`alexandria.db`**, writes **snapshots**, **viewer JSON**, **wall manifests**, and reacts to **bridge** changes on its poll loop.
- **Not required** for GK to *draw* synthetic corridors; **required** for full content, manifests, and DB-backed viewer payloads.

---

## Reconstruction checklist after revert

1. Confirm **one keyspace** in DB + bridge (no mixed `C1_*` and `R1`/`P*` without migration).
2. Confirm **`ALEXANDRIA_DATA`** (or same default **`…/data`**) for GK and LB on desktop.
3. **Realm** = one row; **parcours** under realm; **objects** under each parcour; **20 slots** per parent in snapshot.
4. **`context_key`** selects snapshot; **`focus_key`** selects viewer; **seq** selects frame index.
5. **Práctica inmediata A15** (motores de repaso, bridge, keyspace, alcance): ver **`ORM/ORM-15V4-A15.md`**.

---

*This file is intentionally short. Update it when the product officially switches key vocabulary (e.g. full castillo keys in DB).*
