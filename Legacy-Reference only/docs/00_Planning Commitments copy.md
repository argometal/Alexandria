Cambio 408 — lista consolidada actualizada

Arquitectura base aceptada:

`KEY` nunca se reutiliza.
Borrar final debe migrar a **estado**, no hard delete.
`seq` puede reutilizarse de forma controlada.
Assets se duplican al heredar.
Expansión vía **warp**, no sobrecarga directa.

Modelo futuro reservado para `entries`:

```text
key
parentKey
seq
status (active / archived / vacant / disabled)
originKey
retiredAt
reuseHint
```

Esto sigue **pendiente de fase futura**, no se implementa ahora.

Cambio 409 — estado real actual

Ya estable y usable:

* Builder 13.6 estable
* child creation funcionando
* herencia de imágenes correcta
* assets duplicados correctamente
* capacidad base 10 locus / 10 objects
* SQLite estable
* bridge Godot funcionando
* viewer mínimo funcionando
* hotkeys/F1 actualizados
* delete child y recompact ya existen en lógica actual
* commit de congelación ya hecho para pasar a Godot.

Cambio 410 — pendientes reales reordenados

PRIORIDAD 1 — correcciones estructurales pendientes en Builder

1. **Delete / recompact solo para objects**
2. **Locus bajo parcour no se borra con hotkey**
3. **Locus bajo parcour no se recompacta automático**
4. **Recompact queda solo por comando explícito**
5. **Create child en posición específica (`seq`)**

Estas cinco quedan **pendientes congeladas**, no se tocan ahora.

PRIORIDAD 2 — navegación Godot

6. **Godot leer children reales desde SQLite**
7. **Enter Locus real**
8. **Viewer → Builder roundtrip**

PRIORIDAD 3 — estructura y semántica Builder

9. **Structure panel más claro**
10. **Promote Selection real**
11. **Warp links entre locus**
12. **Hint field en locus**
13. **Indicador visual de role**

PRIORIDAD 4 — tuning visual

14. spacing dinámico frames
15. tuning paneles parcour
16. decidir ocultar roof / walls
17. limpieza de código.

Cambio 411 — pendientes congelados

Siguen congelados:

* reorder complejo
* reciclaje automático de slots
* reuseHint
* gallery cleanup automático
* menús complejos
* migración a modelo por estado en vez de hard delete.

Cambio 412 — siguiente paso activo

La prioridad activa ahora sí pasa a:

**Godot: leer children reales desde SQLite y navegar loci reales.**

Ese es el siguiente frente correcto.

Cambio 476 — en Godot, para que la lógica continúe sin desviarnos, haría esto en orden:

1. **Bloquear Enter Locus en object**
   solo `locus` puede generar room.

2. **Agregar Back / Return to Parcour**
   desde room mínimo volver a `PARCOUR_MAIN`.

3. **Refresh manual sin reiniciar**
   hotkey tipo `F5` o menú.

4. **CurrentParentKey visible en debug**
   para saber si estás en `PARCOUR_MAIN` o en un `locus`.

5. **Frame label / station number arriba**
   para referenciar slot 01–10 visualmente.

6. **Empty slot fallback claro**
   si no hay child en seq, mostrar placeholder y no frame roto.

7. **Validar room mínimo**
   entrar a locus y ver `object 01..10` en los slots.

Cambio 477 — prioridad inmediata real

El más importante ahora es este:

**bloquear Enter Locus en object**.

Porque hoy esa navegación falsa te contamina la lógica y puede hacer parecer que el modelo soporta niveles que no debe soportar.

Cambio 478 — después de eso

Haría:

**Back to Parcour + F5 Refresh + station numbers**.

Con eso ya tienes navegación mínima sana para seguir explorando sin perderte.

