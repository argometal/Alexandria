# ORM-16-08 — Match cards: learning model, review, and text fields (English)

**Index:** [ORM-16-00-Index](./ORM-16-00-Index.md)  
**Related:** [ORM-16-06-MatchCardsLb](./ORM-16-06-MatchCardsLb.md)

---

## 1. What “Match cards” is

**Match cards** is a **Library Build–only** activity: you store **pairs** of **image + text side** in the realm SQLite DB (`lb_match_pairs`). A **practice session** shows a grid of face-down tiles; each pair contributes **two** tiles (image face + text face). You tap to reveal and match the correct image with its text. This is **not** the same as the `type: "card"` **body block** in a locus `body_text` (that is static viewer content in GateKeeper).

**Model in one line:** one row = one **lemma** (required) + **optional transliteration** + **optional gloss (meaning)** + **one image file** under `assets/lb_match_cards/`.

---

## 2. How pairs are “reviewed” today

| Mechanism | Status |
|-----------|--------|
| **Practice session** | Implemented: LB picks up to N pairs (biased toward **lower Fib index**, older `due_at`, higher `fail_count`), shuffles that subset, image↔text matching by pair id. |
| **Fib-style scheduling + due** | **Implemented** in `lb_match_pair_fsrs_state`: `fib_index` uses the same day ladder as locus/parcour (`kParcourFibDays`); `due_at` / `last_review_at` / `reps` / `pass_count` / `fail_count` updated in `lbRecordMatchPairOutcome` (`match_cards_store.dart`). Session UI can show per-pair stats (`match_cards_session_page.dart`). |
| **Full FSRS model** | **Not implemented** for `stability` / `difficulty` / `elapsed_days` (columns exist, unused). |
| **Object recall (`entries`)** | Separate system (Recall grades, etc.). Match cards do **not** write to `entries` today. |

So “review” for match cards = **LB-only spaced-ish practice** on pair rows, **orthogonal** to `entries` recall and `locus_review_*` Fib.

---

## 3. Text fields (lemma, transliteration, gloss)

| Column | Required | Role |
|--------|----------|------|
| `caption_text` | **Yes** | **Lemma / word in native script** (e.g. Cyrillic `кошка`, Japanese 猫, Chinese 猫). Stored as UTF-8. |
| `transliteration` | No | **Romanization** or reading aid (e.g. `koshka`, `neko`). Shown on the text tile below the lemma. |
| `gloss` | No | **Meaning** in a language you choose (e.g. English `cat`, Spanish `gato`). Shown as a third line on the text tile when present. |

The **text tile** in a session shows all non-empty lines (lemma, then transliteration, then gloss). The **image tile** shows only the picture.

---

## 4. Example (Russian vocabulary — same idea as your table)

| Lemma (native) | Transliteration | Meaning | Image (example source) |
|----------------|-----------------|---------|-------------------------|
| кошка | koshka | cat | Pixabay CC0 (user-supplied file in `lb_match_cards/`) |

In the DB: `caption_text = 'кошка'`, `transliteration = 'koshka'`, `gloss = 'cat'`, plus `image_basename` pointing to the copied asset.

**Note:** Alexandria does **not** auto-generate transliteration; you enter it (or leave it empty).

---

## 5. Editorial history

| Version | Note |
|---------|------|
| 1.0 | First ORM-16-08; aligns with `transliteration` / `gloss` columns and LB UI. |
| 1.1 | Scheduling row: Fib + due + counters implemented; FSRS triple still reserved. |
