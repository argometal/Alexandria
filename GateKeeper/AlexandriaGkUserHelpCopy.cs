/// <summary>User help for GateKeeper (F1). Language matches Library Build via <c>bridge/gk_ui_lang.txt</c>.</summary>
public static class AlexandriaGkUserHelpCopy
{
	public static string GetBody()
	{
		return GkUiLocale.ReadGkUiLanguageCode() switch
		{
			"es" => Es,
			"pt" => En, // same as LB until a dedicated PT body is added
			_ => En,
		};
	}

	public const string En = """
BIG PICTURE
Alexandria links two apps on the same data folder. Library Build (LB) edits the realm tree, locus content, images, and reviews. GateKeeper (GK) is the 3D corridor: you walk between frames and open the viewer. Both use the same SQLite database and assets; a small bridge folder tells GK which level and frame are active.

REALMS, PARCOURS, OBJECTS
The tree starts at ROOT, then realms (e.g. R1), the parcour hub (PARCOUR_MAIN), numbered parcours (P1…P20), and object slots under each parcour. Each entry has a cognitive role: Realm (container), Parcour (a sequence of frames along the path), or Object (a leaf you open for full content). In GK, parcour levels show many frames; object levels focus on one frame.

HERO, COLLAGE, BODY
In LB, images can be Viewer-only, Collage (wall panels between frames), or Hero (the 3D frame picture). Saving updates files under assets/<key>/ and snapshots so GK can rebuild the corridor.

LIBRARY BUILD — WHAT YOU CAN DO
Browse levels, edit a locus, search objects, refresh snapshots. The drawer offers PDFs, import, PAO, recall metrics export, language, realm folders, and navigation intent (explore / review / seek / drift). The list shows recall due dates, review history, and parcour review when relevant.

GATEKEEPER — THIS APP
Move with WASD; look with the mouse. Esc frees or recaptures the cursor. Click a frame to set focus for the viewer; from the viewer you can enter a child level or go back to the parent. The top line shows navigation intent from LB. The corridor follows spatial turns set per frame in LB (straight, left, right).

METRICS AND REVIEWS
LB stores recall fields and parcour review ratings per entry. Export CSV from the metrics page. List badges summarize due state when you are under a parcour.

BRIDGE AND SYNC
Files under data/…/bridge/ carry context_key (which snapshot GK loads), focus_key (which locus the viewer highlights), navigation_intent.txt, and refresh flags. After editing in LB, refresh so snapshots stay aligned.

Top-left menu (☰): Help and Previous/Next frame along the parcour if you get stuck.

Press F1 to toggle this help.
""";

	public const string Es = """
VISIÓN GENERAL
Alexandria une dos aplicaciones sobre la misma carpeta de datos. Library Build (LB) edita el árbol del realm, el contenido de cada locus, imágenes y revisiones. GateKeeper (GK) es el corredor 3D: caminas entre marcos y abres el visor. Ambas usan la misma base SQLite y assets; una carpeta bridge indica a GK qué nivel y marco están activos.

REALMS, PARCOURS Y OBJETOS
El árbol parte de ROOT, sigue realms (p. ej. R1), el hub (PARCOUR_MAIN), parcours numerados (P1…P20) y objetos bajo cada parcour. Cada entrada tiene rol: Realm (contenedor), Parcour (secuencia de marcos) u Objeto (hoja con el contenido completo). En GK el parcour muestra muchos marcos; el objeto se centra en uno.

HERO, COLLAGE Y CUERPO
En LB las imágenes pueden ser solo visor, Collage (paneles entre marcos) o Hero (la imagen del marco 3D). Al guardar se actualizan assets y snapshots para que GK regenere el pasillo.

LIBRARY BUILD — QUÉ PUEDES HACER
Navega niveles, edita un locus, busca objetos, refresca snapshots. El menú lateral ofrece PDFs, importación, PAO, exportación de métricas, idioma, carpetas de realm e intent de navegación (explore / review / seek / drift). La lista muestra fechas de recall e historial de Parcour Review cuando aplica.

GATEKEEPER — ESTA APLICACIÓN
Te mueves con WASD y miras con el ratón. Esc libera o vuelve a capturar el cursor. Clic en un marco fija el foco del visor; desde el visor entras al hijo o vuelves al padre. La frase superior muestra el intent desde LB. El pasillo sigue los giros espaciales definidos por marco en LB (recto, izquierda, derecha).

MÉTRICAS Y REVISIONES
LB guarda recall y valoraciones de Parcour Review por entrada. Exporta CSV desde métricas. En la lista hay insignias y tooltips de vencimientos bajo parcour.

BRIDGE Y SINCRONÍA
En data/…/bridge/ están context_key, focus_key, navigation_intent.txt y señales de refresco. Tras editar en LB, usa Refrescar para alinear snapshots.

Menú superior izquierdo (☰): ayuda y marco anterior/siguiente en el parcour si te atascas.

Pulsa F1 para abrir o cerrar esta ayuda.
""";
}
