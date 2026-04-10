# ORM-16-03 — Realm, Castle y completitud (reglas de producto)

**Índice serie:** [ORM-16-00-Index](./ORM-16-00-Index.md)

**Tipo:** reglas **cognitivas / de entrega**, no esquema SQL. El detalle autoritativo de capas y el umbral **80 %** están en **`LAYERS_REALM_PARCOUR_OBJECT.md`**; este archivo solo **ancla** ORM-16 a ese documento para que la serie 16 quede completa frente a “métricas” en sentido amplio.

---

## Resumen operativo

- **Realm (estructural):** árbol bajo una key de realm; en el modelo homogéneo desarrollado hay un tope práctico de **421** filas `entries` (1 + 20 + 400) como **capacidad**, no obligación de autoría.
- **Castle (completitud):** fase completada de un mundo se mide sobre el subconjunto de frames **usados** en la experiencia autorada, no sobre todo el árbol.
- **Criterio documentado en LAYERS:** “califica Castle” cuando **≥ 80 %** de los frames **usados** alcanzan el nivel acordado (p. ej. ridiculous-stories), no el 80 % de 421.

**Implementación:** la definición exacta de “frame usado” y flags en DB es responsabilidad conjunta producto + LB; ORM-16-03 **no** duplica columnas: ver `LAYERS_REALM_PARCOUR_OBJECT.md` y código de seeds/review.

---

## Relación con ORM-16-02

Las métricas de **repaso** (Recall, Fibonacci, parcour) miden *progreso de memoria / estudio*. **Castle** mide *cierre de producto* sobre un subconjunto narrado — vectores distintos; no mezclar denominadores.

---

## Historial editorial

| Versión | Nota |
|---------|------|
| 1.0 | Creación; puntero a LAYERS para no divergir. |
