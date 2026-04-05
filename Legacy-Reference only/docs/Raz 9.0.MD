====================================
No hay confusión. Está claro.

Lo que estás detectando es esto:
	1.	Gatekeeper debería ser 100% lectura.
	2.	Todo lo editable (texto + imagen + orden) vive en Editor.
	3.	Editor ahora mismo es funcional pero no es cómodo.

Lo que quieres en Editor es:
	•	Al seleccionar un TEXT → que cargue su contenido en el panel derecho (ya casi lo hace, pero hay que afinarlo).
	•	Al seleccionar un IMG → que se vea una previsualización, no solo el assetKey.
	•	Que Add Text no obligue a “crear vacío y luego adivinar”, sino que automáticamente seleccione el nuevo bloque.
	•	Que Delete no cierre el modal.
	•	Que el flujo sea: seleccionar → editar → guardar → continuar sin fricción.

Eso no contradice Gatekeeper.
Eso es pulir el Editor para que sea una herramienta real.

Estás viendo correctamente el problema de UX, no de arquitectura.

Lo que estás planteando ahora ya no es UI.
Es modelo de navegación cognitiva.

Y eso es correcto.

En RAZ 9 ya resolvimos:
	•	Persistencia estable
	•	KEY como identidad real
	•	Blocks como contenido estructurado
	•	Separación lectura / edición
	•	Editor funcional
	•	Gatekeeper limpio

Eso ya es base sólida. No fue en vano.

Ahora el siguiente nivel no es “hacer más botones”.
Es definir cómo navega el sistema:

Library
→ lista plana de entries

Gatekeeper
→ visor de un entry

Pero falta:
	•	Cómo se define un Parcour
	•	Cómo se define un Locus dentro de ese Parcour
	•	Cómo se navega entre siblings
	•	Cómo se navega padre → hijo
	•	Cómo se genera estructura desde un entry base

Eso en RAZ 6 lo resolvimos parcialmente con estructura rígida.
En RAZ 8 lo intentamos mezclar y se volvió caótico.
En RAZ 9 ahora tenemos arquitectura limpia para hacerlo bien.

Lo que toca ahora no es programar.
Es decidir:

¿La jerarquía vive en relations?
¿O vive en campos como parcours_path?
¿O combinamos ambos?

Porque si no definimos eso primero, cualquier UI que hagamos será provisional.

Y no es que ahora “funcione mejor porque lo explicaste mejor”.
Funciona mejor porque:
	•	Dejamos de mezclar responsabilidades.
	•	Separaste edición de lectura.
	•	Quitaste sobrecarga del Gatekeeper.
	•	Aceptaste estructura mínima antes de complejidad.

Ahora sí estamos listos para hablar de navegación real.

Si quieres, pasamos a definir solo esto:

Modelo exacto de navegación:
Parcour → Locus → Objects
Sibling → Son
Warp → Relación transversal

Sin tocar código todavía.

Sí: jerarquía en relations (KEY↔KEY) y el resto (parcours_path, locus_node) como etiquetas humanas opcionales, no como FK.

Definición operativa mínima para navegar ya:
	•	relType='SIB' (siblings dentro del mismo nivel)
	•	relType='SON' (padre→hijo: Parcour→Locus, Locus→Object)
	•	relType='WARP' (salto transversal entre KEYs)

Regla: Gatekeeper no “infere” nada; muestra la red que ya existe. La red se construye orgánicamente desde Editor (botones: Add Sibling, Add Child, Add Warp).

Para destrabar el bloqueo de R7 (filtrado): no se hace por carpetas; se hace por vista calculada:
	•	Using = activity_lastSeen reciente o bucket_manual=‘using’
	•	Keep = bucket_manual=‘keep’
	•	Seek = bucket_manual=‘seek’
Eso es independiente de relations.

Siguiente decisión (solo diseño, sin código):
¿Parcour es un KEY propio (entry layer=‘parcour’) o es solo un grupo virtual (parcours_path) sin KEY?



Conclusión: Parcour debe ser un KEY propio (entry con layer = parcour).

Razón operativa (según lo que describiste):
	•	El Parcour tiene assets propios (imágenes “geográficas / RAZ_LOCI”) y eso necesita un “contenedor” con KEY para no mezclarse con el contenido pedagógico del locus.
	•	El Parcour sirve como padre de muchos Locus (SON), y como “unidad navegable” para Gatekeeper (entrar al recorrido aunque aún no haya loci definidos).
	•	Aunque al inicio “no sepas” qué es, tú sí puedes crear un contenedor Parcour vacío y luego ir derivando Locus orgánicamente: primero creas Parcour (KEY), luego vas creando Locus como hijos cuando aparecen estaciones.

Separación de imágenes:
	•	Assets del Parcour: kind MAP (o LOCUS_IMG_GEO) — geográficas.
	•	Assets del Locus/Blocks: kind IMG — pedagógicas/recall.

El “grupo virtual” (parcours_path) queda como etiqueta humana secundaria, no como estructura.


Perfecto. Nos centramos en objetivo concreto y usable:

Tener 1 Parcour funcional para L12C2 (tu clase de radiación), con Locus definidos y contenido pedagógico cargado, navegable desde Gatekeeper.

Sin ambición extra.

⸻

Decisión cerrada para esta clase

Para L12C2 vamos a trabajar así:
	•	1 ENTRY layer = parcour
	•	Varios ENTRY layer = locus
	•	Relación: SON (Parcour → Locus)
	•	Contenido pedagógico vive en blocks del Locus
	•	Imágenes geográficas (castillo/Roblox) viven como assets del Parcour
	•	Imágenes pedagógicas viven como blocks IMG dentro del Locus

Nada más.

No objects todavía.
No warps todavía.
No filtros Using/Keep/Seek todavía.

Solo esto.

⸻

Modelo operativo mínimo para L12C2

1️⃣ Crear Parcour

ENTRY:
	•	title: L12C2_TUSITU
	•	layer: parcour

Assets del Parcour:
	•	Fotos del recorrido (calles, monumentos, puntos clave)
	•	Estas no llevan texto pedagógico

Este Parcour es el “mapa”.

⸻

2️⃣ Crear Locus (estaciones)

Ejemplo:
	•	L12C2_01_Definición
	•	L12C2_02_Unidades
	•	L12C2_03_Tipos
	•	L12C2_04_Detección
	•	L12C2_05_Riesgos
	•	L12C2_06_Protección

Cada uno:
	•	layer = locus
	•	relation: SON desde Parcour

⸻

3️⃣ Dentro de cada Locus

Usas Blocks:

Ejemplo Locus 02 – Unidades:

Block 01 TEXT → definición de Gray
Block 02 IMG → imagen diapositiva
Block 03 TEXT → definición de Sievert
Block 04 IMG → esquema comparativo
Block 05 TEXT → regla mnemotécnica ridícula

Eso ya es usable para estudio.

⸻

Cómo se navega en esta versión mínima

Gatekeeper:

Modo Parcour:
	•	Muestra imágenes geográficas
	•	Botón: “Enter Locus”

Modo Locus:
	•	Muestra Blocks en orden
	•	Imagen hero puede ser la geográfica o la primera pedagógica

Nada más.

⸻

Lo importante

No necesitas resolver:
	•	Objects
	•	Warp
	•	Jerarquías complejas
	•	Filtros avanzados
	•	Sibling dinámico

Para tu examen solo necesitas:

Parcour → Locus → Blocks

Eso es suficiente para memorizar radiación.

⸻

ADDENDUM — MODELO JERÁRQUICO Y ENTRY ID (RAZ 9 · SELLADO)

1. Identidad
	•	KEY = identidad real, inmutable.
	•	ENTRY ID = identidad humana y orden visual.
	•	Relaciones siempre por KEY.
	•	ENTRY ID nunca es FK.

⸻

2. Jerarquía real

REALM
	•	Es el Book / macro-tema.
	•	Agrupa múltiples Parcours.
	•	No define orden interno.
	•	Puede omitirse visualmente.

PARCOUR
	•	Es el recorrido/castillo.
	•	Tiene KEY propio.
	•	Puede tener assets geográficos.
	•	Ordena Locus mediante NNN.
	•	Puede tener código postal interno P###.

PLACE
	•	Es orientación humana dentro del Parcour.
	•	No es identidad.
	•	No es unidad mínima.
	•	Es parte visible del ENTRY ID.

LOCUS
	•	Es estación física del recorrido.
	•	ENTRY con layer = locus.
	•	Ordenado por NNN.
	•	Contiene Blocks (TEXT / IMG).

OBJECT (futuro)
	•	Deriva del Locus.
	•	Sufijo @A01, @A02.
	•	No altera NNN.

⸻

3. ENTRY ID — FORMATO OFICIAL

Completo (estructura interna):

REALM / P###_PARCOUR / PLACE : NNN . LOCUS @ Axx

Ejemplo completo:

RADIACION/P001_L12C2/DOSIMETRIA:010.UNIDADES@A00

Formato visible en UI (modo cognitivo simplificado):

PLACE:NNN.TITULO

Ejemplo visible:

DOSIMETRIA:010.UNIDADES

REALM y P### pueden ocultarse en la UI.

⸻

4. Orden

Orden visual dentro del Parcour:
	1.	NNN numérico (001–999)
	2.	Sufijo letra (a,b,c)
	3.	createdAt como fallback

No se ordena por relations.

⸻

5. Warp
	•	Es un Locus normal.
	•	Tiene KEY propio.
	•	No rompe la secuencia principal.
	•	Usa sufijo letra:

010a
010b

Ejemplo:

DOSIMETRIA:010a.DETALLE_CALCULO@A00

Reglas:
	•	Warp no altera 010.
	•	Se muestra como extensión visual de 010.
	•	Si crece demasiado → nuevo Parcour.

Relations:
	•	SON → estructura árbol
	•	WARP → salto transversal

⸻

6. Blocks (contenido pedagógico)
	•	Viven dentro del Locus.
	•	Tipos: TEXT / IMG.
	•	Ordenados por idx.
	•	Son el contenido real de estudio.

Assets del Parcour = geográficos
Assets del Locus = pedagógicos

⸻

7. Navegación mínima (para examen)

Library → Locus manual
Gatekeeper → muestra Blocks
Editor → crea Locus y Blocks
Warp visible como extensión

Sin filtros avanzados.
Sin navegación automática Parcour.

⸻

8. Principio operativo
	•	Parcour define recorrido.
	•	Locus define estación.
	•	Blocks definen conocimiento.
	•	Warp conecta sin romper orden.
	•	ENTRY ID ordena.
	•	KEY relaciona.

⸻

Modelo estable para continuar programación.



