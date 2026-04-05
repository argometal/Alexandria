====================================
CONTRATO RAZ 8.0 (ALEXANDRIA) — SELLADO PARA INSTRUCCIONES FIJAS

Objetivo
Crear un sistema de estudio usable y estable, donde la interfaz desaparezca y el foco sea aprender.

Principios no negociables
	•	Uso real > elegancia.
	•	Una función por ventana.
	•	Layout fijo y estable (sin SplitContainer).
	•	Cambios por archivo, en bloques atómicos con rollback.
	•	Autoridad del usuario prevalece.

Arquitectura UI
	•	Library (Explorer): explorar, filtrar, buscar, importar/exportar. No estudiar aquí.
	•	Viewer (Gatekeeper): estudiar únicamente. Ventana independiente.
	•	Builder: edición ocasional. Nunca visible por defecto.

Modelo de navegación
	•	Nivel 1: Vistas — All / Using / Keep / Seek.
	•	Nivel 2: Estructura — ROOT / REALM / PARCOUR.
	•	Nivel 3: Lista — Search arriba, filas grandes y legibles.
	•	Viewer se abre con Enter o doble click.

Diseño visual (tema sellado)
	•	Fondo: #121212 o #181A1B.
	•	Texto primario: #E6E6E6.
	•	Texto secundario: #9AA0A6.
	•	Acento único: #4C8DFF.
	•	Estados suaves: Pass #6FAF8F, Fail #C97A7A.
	•	Sin gradientes, sin colores vivos.

Escalado
	•	UI_SCALE global.
	•	Tamaños base fijos: font, row height, padding.
	•	Sin paneles dinámicos.

Datos
	•	Modelo Locus/KEY.
	•	Append-only.
	•	SQLite/DAO no se tocan en fase inicial.

Reglas de ejecución
Cada cambio debe incluir:
	•	Archivo único.
	•	Objetivo del bloque.
	•	BEFORE completo.
	•	AFTER completo.
	•	Verificación (build/run).
Si algo no cuadra → se para.

Criterio de éxito
	•	Poder estudiar 30–60 min seguidos sin fricción.
Si no se cumple → fallo.

Kill switch
	•	Si vuelve el apilamiento o la fricción, se detiene y se corrige sin debate.

— Fin del contrato RAZ 8.0