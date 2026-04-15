// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Biblioteca de realms';

  @override
  String activeRealmLabel(String realm) {
    return 'Realm activo: $realm';
  }

  @override
  String get sectionReading => 'LECTURA';

  @override
  String get sectionImport => 'IMPORTAR';

  @override
  String get sectionPao => 'PAO';

  @override
  String get sectionMatchCards => 'CARTAS';

  @override
  String get sectionGo => 'GO';

  @override
  String get sectionMetrics => 'MÉTRICAS';

  @override
  String get sectionSystem => 'SISTEMA';

  @override
  String get sectionLanguage => 'IDIOMA';

  @override
  String get nodeReaderTitle => 'Lector de nodo';

  @override
  String get nodeReaderSubtitle => 'Parcour u objeto (lista)';

  @override
  String get pdfNodeTitle => 'PDF de nodo';

  @override
  String get pdfNodeSubtitle => 'Objeto u otra entrada';

  @override
  String get pdfParcourTitle => 'PDF de parcour';

  @override
  String get pdfParcourSubtitle => 'Un parcour por exportación';

  @override
  String get importLocusTitle => 'Importar contenido a locus';

  @override
  String get importLocusSubtitle => 'Desde data-transfer/out/ → body_text';

  @override
  String get paoEditorTitle => 'PAO (00–99)';

  @override
  String get paoEditorSubtitle => 'Sistema de 2 dígitos · import / export JSON';

  @override
  String get paoPracticeTitle => 'PAO · práctica individual';

  @override
  String get paoPracticeSubtitle =>
      'Recall mental · mostrar respuestas · acierto/fallo';

  @override
  String get matchCardsTitle => 'Cartas (emparejar)';

  @override
  String get matchCardsSubtitle => 'Imagen ↔ pie · sesión aleatoria (solo LB)';

  @override
  String get matchCardsOrmHint =>
      'Cada par: lema (escritura nativa), transliteración opcional, significado (gloss) opcional e imagen. route_key es para un futuro «por ruta»; la tabla FSRS existe pero sin planificador.';

  @override
  String get matchCardsEmpty =>
      'Aún no hay pares. Añade una imagen y un pie de texto.';

  @override
  String get matchCardsAddPair => 'Añadir par';

  @override
  String get matchCardsPractice => 'Practicar';

  @override
  String get matchCardsDeleteTooltip => 'Quitar par';

  @override
  String get matchCardsAddDialogTitle => 'Nuevo par';

  @override
  String get matchCardsLemmaLabel => 'Lema / palabra (escritura nativa)';

  @override
  String get matchCardsLemmaHint => 'ej. кошка';

  @override
  String get matchCardsLemmaRequired => 'Escribe primero el lema.';

  @override
  String get matchCardsTransliterationLabel => 'Transliteración (opcional)';

  @override
  String get matchCardsTransliterationHint => 'ej. koshka';

  @override
  String get matchCardsGlossLabel => 'Significado (opcional)';

  @override
  String get matchCardsGlossHint => 'ej. gato · cat';

  @override
  String get matchCardsPickImage => 'Elegir imagen';

  @override
  String get matchCardsCancel => 'Cancelar';

  @override
  String get matchCardsSessionTitle => 'Sesión de emparejamiento';

  @override
  String get matchCardsNeedTwoPairs =>
      'Añade al menos dos pares en Cartas para jugar.';

  @override
  String get matchCardsNoMatch => 'No coinciden — prueba otra vez.';

  @override
  String get matchCardsPlayAgain => 'Otra vez';

  @override
  String matchCardsAttempts(int count) {
    return 'Intentos: $count';
  }

  @override
  String get matchCardsComplete => 'Completado';

  @override
  String get matchCardsPairsRemaining => 'pares restantes';

  @override
  String get matchCardsPasteDropHint =>
      'Pegar imagen: Ctrl+V (⌘V en Mac) fuera del campo de texto. O suelta un archivo aquí. Los pies admiten cualquier escritura (chino, japonés, ruso…).';

  @override
  String get matchCardsLemmaUnicodeHelper => 'Cualquier escritura — UTF-8.';

  @override
  String get matchCardsImageReady => 'Imagen lista — escribe el pie y guarda.';

  @override
  String get matchCardsPasteImageInDialog => 'Pegar imagen del portapapeles';

  @override
  String get matchCardsSavePair => 'Guardar par';

  @override
  String get matchCardsImageRequired =>
      'Elige, pega o suelta una imagen primero.';

  @override
  String get matchCardsClipboardNoImage => 'El portapapeles no tiene imagen.';

  @override
  String get matchCardsDeckLabel => 'Mazo';

  @override
  String get matchCardsDeckMenuTooltip => 'Mazos · exportar · importar';

  @override
  String get matchCardsNewDeckMenu => 'Mazo nuevo…';

  @override
  String get matchCardsRenameDeckMenu => 'Renombrar mazo…';

  @override
  String get matchCardsDeleteDeckMenu => 'Eliminar mazo…';

  @override
  String get matchCardsExportMenu => 'Exportar mazo (.zip)…';

  @override
  String get matchCardsImportMenu => 'Importar mazo (.zip)…';

  @override
  String get matchCardsNewDeckTitle => 'Mazo nuevo';

  @override
  String get matchCardsRenameDeckTitle => 'Renombrar mazo';

  @override
  String get matchCardsDeleteDeckTitle => '¿Eliminar mazo?';

  @override
  String get matchCardsDeleteDeckBody =>
      'Los pares de este mazo pasarán a otro mazo.';

  @override
  String get matchCardsDeleteDeckConfirm => 'Eliminar';

  @override
  String get matchCardsDeckNameLabel => 'Nombre';

  @override
  String get matchCardsExportTitle => 'Guardar exportación';

  @override
  String get matchCardsExportDone => 'Exportación guardada.';

  @override
  String matchCardsExportError(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get matchCardsImportTitle => 'Mazo nuevo para importar';

  @override
  String get matchCardsImportDefaultDeckName => 'Importado';

  @override
  String get matchCardsImportNewDeckNameLabel => 'Nombre del mazo';

  @override
  String get matchCardsImportNewDeckNameHelper =>
      'Los pares del archivo se añaden a este mazo nuevo.';

  @override
  String get matchCardsImportConfirm => 'Importar';

  @override
  String matchCardsImportDone(int count) {
    return 'Importados $count par(es).';
  }

  @override
  String matchCardsImportError(String error) {
    return 'Error al importar: $error';
  }

  @override
  String get matchCardsSearchHint =>
      'Buscar lema, transliteración, significado…';

  @override
  String get matchCardsDuplicatesOnly => 'Solo duplicados';

  @override
  String matchCardsDuplicateSummary(int groups) {
    return '$groups lema(s) repetido(s) en este mazo';
  }

  @override
  String get matchCardsSearchNoResults =>
      'Ninguna carta coincide con la búsqueda o el filtro.';

  @override
  String get matchCardsDuplicateLemmaTooltip =>
      'Mismo lema que otra carta en este mazo';

  @override
  String get matchCardsDuplicateSaveTitle => 'Lema duplicado';

  @override
  String get matchCardsDuplicateSaveBody =>
      'Ya existe un par con este lema en el mazo.';

  @override
  String get matchCardsContinueAnyway => 'Guardar igual';

  @override
  String get goGameTitle => 'Go 9×9';

  @override
  String get goGameSubtitle =>
      'Capturas, sin suicidio, superko posicional. Dos pasos seguidos terminan. Komi para blancas.';

  @override
  String get goGameModePvp => 'Dos jugadores';

  @override
  String get goGameModeBot => 'vs Bot (tú negras)';

  @override
  String get goGameNew => 'Partida nueva';

  @override
  String get goGamePass => 'Pasar';

  @override
  String get goGameBlackTurn => 'Juegan negras';

  @override
  String get goGameWhiteTurn => 'Juegan blancas';

  @override
  String get goGameBotThinking => 'Bot pensando…';

  @override
  String get goGameIllegal => 'Jugada ilegal';

  @override
  String get goGameOver => 'Fin de partida';

  @override
  String goGameScoreLine(String blackPt, String whitePt, String komi) {
    return 'Negras $blackPt — Blancas $whitePt (komi +$komi)';
  }

  @override
  String get metricsRecallTitle => 'Métricas recall';

  @override
  String get metricsRecallSubtitle => 'Exportar CSV';

  @override
  String get realmsTitle => 'Reinos';

  @override
  String get realmsSubtitle => 'Núcleo · Activo · Explorar';

  @override
  String get navigationIntentTitle => 'Intent de navegación';

  @override
  String get navigationIntentTooltip =>
      'Modo explore / review / seek / drift. Si hay foco en un objeto, se guarda como «marco»: place, hint y ridiculous story van ligados al Hero de ese mismo locus.';

  @override
  String get menuTooltip => 'Menú';

  @override
  String get backTooltip => 'Subir';

  @override
  String get searchTooltip =>
      'Buscar objetos (FTS5) · Núcleo · Activo · Explorar';

  @override
  String get refreshTooltip => 'Regenerar snapshot / lista';

  @override
  String get emptyLevelMessage =>
      'No hay entradas en este nivel.\nVuelve atrás para continuar.';

  @override
  String get tooltipDoubleTapObject =>
      'Doble clic: visor de contenido (Node card)';

  @override
  String get tooltipDoubleTapEnter => 'Doble clic para entrar al nivel';

  @override
  String get tooltipRoleObject =>
      'Rol (solo LB). Doble clic: visor de contenido.';

  @override
  String get tooltipRoleEnter =>
      'Rol (solo LB; GK no lo lee). Doble clic en la fila para entrar.';

  @override
  String lastReviewPrefix(String when) {
    return '·  Última revisión: $when';
  }

  @override
  String duePrefix(String when) {
    return '·  Vence: $when';
  }

  @override
  String get roleRealm => 'Realm';

  @override
  String get roleParcour => 'Parcour';

  @override
  String get roleObject => 'Objeto';

  @override
  String get languageTitle => 'Idioma de la interfaz';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get languageSystem => 'Idioma del dispositivo';

  @override
  String get languageChanged => 'Idioma actualizado';

  @override
  String get edit => 'Editar';

  @override
  String get moveObjectTooltip =>
      'Mover a otro parcour / slot (reemplaza destino)';

  @override
  String get moveParcourTooltip => 'Mover a otro parcour (reemplaza destino)';

  @override
  String get studyTooltip => 'Estudio';

  @override
  String get reviewAgain => 'Otra vez';

  @override
  String get reviewHard => 'Difícil';

  @override
  String get reviewGood => 'Bien';

  @override
  String get reviewEasy => 'Fácil';

  @override
  String statsRecallLine(int due, int n, int total) {
    return 'Recall (entradas) · vencen $due · nuevas $n · total $total';
  }

  @override
  String parcourRowRecallLine(int due, int n, int total) {
    return 'Recall · vencen $due · nuevas $n · total $total';
  }

  @override
  String get realmNA => 'Realm: N/D';

  @override
  String realmPercent(int percent, int good, int active) {
    return 'Realm: $percent% (good $good / activos $active)';
  }

  @override
  String get dialogMoveParcourTitle => 'Mover parcour';

  @override
  String get dialogMoveObjectTitle => 'Mover objeto';

  @override
  String originLabel(String key) {
    return 'Origen: $key';
  }

  @override
  String get moveParcourHint =>
      'Elige el parcour que sustituirá al destino (mismo número de hijos objeto).';

  @override
  String get moveParcourBodyWarning =>
      'Se borra el subárbol del destino y se sustituye por el del origen. El hueco del origen vuelve al esqueleto vacío (L1…L20).';

  @override
  String get destinationParcourLabel => 'Parcour destino';

  @override
  String get moveObjectBodyWarning =>
      'Si el slot destino ya tiene contenido, se sustituye. El hueco en el parcour de origen se rellena con el esqueleto.';

  @override
  String get slotLabel => 'Slot (1–20)';

  @override
  String get moveObjectHint =>
      'Elige parcour destino y slot (seq). El objeto pasa a Parent_O## de ese seq.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get move => 'Mover';

  @override
  String get snackbarNoDestParcour => 'No hay otro parcour como destino.';

  @override
  String snackbarParcourMoved(String from, String to) {
    return 'Parcour movido: $from → $to';
  }

  @override
  String get snackbarNoParcoursUnderHub => 'No hay parcours bajo PARCOUR_MAIN.';

  @override
  String snackbarObjectMoved(String obj, String dest) {
    return 'Objeto movido: $obj → $dest';
  }

  @override
  String snackbarNuclearError(String error) {
    return 'Error al borrar: $error';
  }

  @override
  String get breadcrumbRoot => 'R1';

  @override
  String get breadcrumbParcours => 'Parcours (R1)';

  @override
  String intentFrameSuffix(String focus) {
    return ' · marco $focus';
  }

  @override
  String intentDrawerWithFrame(String mode, String frame) {
    return '$mode · marco $frame';
  }

  @override
  String intentSnackbar(String mode, String frameSuffix) {
    return 'Intent → $mode$frameSuffix (HUD GateKeeper)';
  }

  @override
  String keySeqLine(String key, String seq) {
    return 'clave=$key  ·  seq=$seq';
  }

  @override
  String parcourReviewTooltip(String rating) {
    return 'Último Parcour Review: $rating';
  }

  @override
  String get parcourReviewNoData => 'sin dato';

  @override
  String get timeReviewNever => 'nunca';

  @override
  String get timeReviewUpcoming => 'futuro';

  @override
  String get timeReviewToday => 'hoy';

  @override
  String get timeReviewYesterday => 'ayer';

  @override
  String timeReviewDaysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String timeReviewWeeksAgo(int count) {
    return 'hace $count semanas';
  }

  @override
  String timeReviewMonthsAgo(int count) {
    return 'hace $count meses';
  }

  @override
  String timeReviewYearsAgo(int count) {
    return 'hace $count años';
  }

  @override
  String get dueTagNew => 'nuevo';

  @override
  String get dueTagDue => 'vence';

  @override
  String dueTagInHours(int h) {
    return 'en ${h}h';
  }

  @override
  String dueTagInDays(int d) {
    return 'en ${d}d';
  }

  @override
  String get fibScheduleEmpty => 'Fib · sin objetos bajo este nivel';

  @override
  String fibScheduleLine(String prev, String next) {
    return 'Fib · última: $prev · próximo: $next';
  }

  @override
  String get fibOverdue => 'vencido';

  @override
  String fibRelPastMinutes(int m) {
    return 'hace ${m}m';
  }

  @override
  String fibRelPastHours(int h) {
    return 'hace ${h}h';
  }

  @override
  String fibRelPastDays(int d) {
    return 'hace ${d}d';
  }

  @override
  String fibRelFutureMinutes(int m) {
    return 'en ${m}m';
  }

  @override
  String fibRelFutureHours(int h) {
    return 'en ${h}h';
  }

  @override
  String fibRelFutureDays(int d) {
    return 'en ${d}d';
  }

  @override
  String get parcourFibDueDash => 'due —';

  @override
  String get parcourFibDueOverdue => 'due vencido';

  @override
  String parcourFibDueIn(String when) {
    return 'due $when';
  }

  @override
  String get parcourFibScoreDash => 'score —';

  @override
  String parcourFibScoreValue(String value) {
    return 'score $value';
  }

  @override
  String parcourFibFullLine(int fibIndex, String due, String score) {
    return 'Parcour · fib $fibIndex · $due · $score';
  }

  @override
  String get locusEditorTitle => 'Editor de locus';

  @override
  String get locusEditorAddBlockTooltip => 'Añadir bloque';

  @override
  String get locusEditorBlockParagraph => 'Párrafo';

  @override
  String get locusEditorBlockLink => 'Enlace';

  @override
  String get locusEditorBlockImage => 'Imagen';

  @override
  String get locusEditorBlockCard => 'Tarjeta';

  @override
  String get locusEditorCardWordLabel => 'Palabra / lema';

  @override
  String get locusEditorCardImageLabel => 'Ilustración (archivo en assets)';

  @override
  String get locusEditorCardPhoneticLabel =>
      'Fonética / notas (archivo, p. ej. ipa.txt)';

  @override
  String get locusEditorCardAudioLabel =>
      'Audio de pronunciación (ogg / mp3 / wav)';

  @override
  String get locusEditorCardRelatedLabel => 'Claves de entradas relacionadas';

  @override
  String get locusEditorCardRelatedHint =>
      'Separadas por coma o espacio (deben existir en este realm)';

  @override
  String get locusEditorEmptyBlocksHint =>
      'Aún no hay bloques. Añade párrafo, enlace, imagen o tarjeta de vocabulario, o pega o suelta una imagen.';

  @override
  String locusEditorUnknownRelatedKey(String key) {
    return 'Clave relacionada inexistente en este realm: $key';
  }

  @override
  String get locusEditorSpatialTurnTooltip =>
      'Giro espacial (recorrido al siguiente marco en GateKeeper)';

  @override
  String get locusEditorSpatialStraight => 'Recto';

  @override
  String get locusEditorSpatialLeft => 'Izquierda';

  @override
  String get locusEditorSpatialRight => 'Derecha';

  @override
  String get locusEditorMenuTooltip => 'Ajustes del locus, rol, ayuda';

  @override
  String get locusEditorSave => 'Guardar';

  @override
  String get locusEditorPasteHint =>
      'Pegar: Ctrl+V. Roles de imagen: Viewer / Collage / Hero. Hero rápido: imagen + Ctrl/Cmd+H. Más: menú ☰';

  @override
  String get locusEditorSaved => 'Guardado';

  @override
  String locusEditorSubtitleLine(String role, String turn) {
    return '$role · $turn';
  }

  @override
  String get sectionHelp => 'AYUDA';

  @override
  String get helpGuideTitle => 'Cómo funciona Alexandria';

  @override
  String get helpGuideClose => 'Cerrar';

  @override
  String get helpGuideGkHint => 'En GateKeeper pulsa F1 para ver esta guía.';

  @override
  String get helpGuideOverviewTitle => 'Visión general';

  @override
  String get helpGuideOverviewBody =>
      'Alexandria une dos aplicaciones sobre la misma carpeta de datos. Library Build (LB) sirve para editar el árbol del realm, el contenido de cada locus, imágenes y revisiones. GateKeeper (GK) es el corredor 3D: caminas entre marcos y abres el visor. Ambas leen la misma base SQLite y assets; una carpeta bridge indica a GK qué nivel y marco están activos.';

  @override
  String get helpGuideRolesTitle => 'Realms, parcours y objetos';

  @override
  String get helpGuideRolesBody =>
      'El árbol parte de ROOT, sigue realms (p. ej. R1), el hub de parcours (PARCOUR_MAIN), parcours numerados (P1…P20) y objetos bajo cada parcour. Cada fila tiene rol cognitivo: Realm (contenedor), Parcour (secuencia de marcos en el pasillo) u Objeto (hoja que abres para ver todo el contenido). En LB asignas roles al crear o editar. En GK el parcour muestra muchos marcos a lo largo del recorrido; el objeto se centra en un marco.';

  @override
  String get helpGuideContentTitle => 'Hero, collage y cuerpo';

  @override
  String get helpGuideContentBody =>
      'En el editor de locus, las imágenes pueden ser solo visor, Collage (paneles en la pared del GK entre marcos) o Hero (la imagen del marco 3D). Los bloques de texto pueden llevar place, hint o ridiculous story para estudio. Al guardar se actualizan archivos en assets/<clave>/ y los snapshots para que GK regenere el corredor.';

  @override
  String get helpGuideCardsTitle => 'Tarjetas de vocabulario';

  @override
  String get helpGuideCardsBody =>
      'Añade un bloque Tarjeta para entradas tipo idioma: palabra destacada, ilustración en assets/<clave>/, fonética opcional (.txt), audio opcional (ogg/mp3/wav) y related_to con otras claves del realm. En GateKeeper, las relacionadas solo cambian el foco (mismo corredor); Atrás vuelve al foco anterior.';

  @override
  String get helpGuideLbTitle => 'Library Build — qué puedes hacer';

  @override
  String get helpGuideLbBody =>
      'Navega con la barra y el cajón: abre cualquier nivel, edita un locus (doble toque o editar), busca objetos, refresca snapshots. El menú lateral ofrece PDF de nodo, PDF de parcour, importación desde data-transfer, herramientas PAO, exportación de métricas recall, idioma, carpetas de realm e intent de navegación (explore / review / seek / drift — opcionalmente ligado a un locus en foco para campos del Hero). La lista muestra fechas de recall, historial de revisión, semáforo de Parcour Review y líneas Fib cuando aplica.';

  @override
  String get helpGuideGkTitle => 'GateKeeper — realm 3D';

  @override
  String get helpGuideGkBody =>
      'Te mueves con WASD y miras con el ratón (Esc libera o vuelve a capturar el cursor). Clic en un marco fija el foco del visor; desde el visor entras al nivel hijo o vuelves al padre. La frase superior muestra el intent de navegación desde LB. El trazado del pasillo sigue los giros espaciales que defines por marco en LB (recto, izquierda, derecha).';

  @override
  String get helpGuideMetricsTitle => 'Métricas y revisiones';

  @override
  String get helpGuideMetricsBody =>
      'LB guarda por entrada campos de recall (próxima revisión, fuerza, contadores) y valoraciones de Parcour Review. La página de métricas exporta CSV. En la lista, insignias y tooltips resumen vencimientos y la última Parcour Review bajo un parcour.';

  @override
  String get helpGuideBridgeTitle => 'Bridge y sincronía';

  @override
  String get helpGuideBridgeBody =>
      'Archivos en data/…/bridge/ llevan context_key (qué nivel de snapshot carga GK), focus_key (qué locus destaca el visor), navigation_intent.txt y señales de refresco. Tras editar en LB, usa Refrescar para alinear snapshots y manifiestos; GK reacciona cuando esos archivos cambian.';

  @override
  String get usageBandAll => 'Todos';

  @override
  String get usageBandCore => 'Núcleo';

  @override
  String get usageBandActive => 'Activo';

  @override
  String get usageBandSeek => 'Explorar';

  @override
  String get usageBandSubtitleCore => 'Núcleo de uso (mayor engagement)';

  @override
  String get usageBandSubtitleActive => 'Recurrente';

  @override
  String get usageBandSubtitleSeek => 'Exploración / cola larga';

  @override
  String get realmShelfPopupCore => 'Núcleo — prioridad';

  @override
  String get realmShelfPopupActive => 'Activo — uso regular';

  @override
  String get realmShelfPopupSeek => 'Explorar — resto';

  @override
  String get realmAdminFabCreate => 'Crear realm nuevo';

  @override
  String get realmAdminTabFolders => 'Carpetas';

  @override
  String get realmAdminTabShelves => 'Estantes';

  @override
  String get realmAdminTooltipEmptySubfolder =>
      'Carpeta vacía (solo organización, sin realm)';

  @override
  String get realmAdminTooltipRefresh => 'Actualizar lista';

  @override
  String get realmAdminTooltipOpenExplorer =>
      'Abrir esta carpeta en el explorador';

  @override
  String get realmAdminTooltipCreateSeed =>
      'Crear realm seed del realm activo (data/realm_seed/)';

  @override
  String get realmAdminTooltipNuclear => 'Borrar toda la data (irreversible)';

  @override
  String get realmAdminTooltipOpenRealmFolder =>
      'Abrir carpeta del realm en el explorador';

  @override
  String get realmAdminTooltipMoveShelf => 'Cambiar estante';

  @override
  String get realmAdminTooltipEnterSubfolders => 'Entrar en subcarpetas';

  @override
  String get realmAdminTooltipShelfMenu => 'Estante';

  @override
  String get realmAdminTooltipMoveRealm =>
      'Mover o renombrar el realm en disco';

  @override
  String get realmAdminMoveRealmMenu => 'Mover a ruta…';

  @override
  String get realmAdminMoveRealmTitle => 'Mover realm';

  @override
  String get realmAdminMoveRealmBody =>
      'Nueva ubicación bajo data/realms/. El destino no debe existir. La base de datos se cierra un momento.';

  @override
  String get realmAdminMoveRealmTargetLabel => 'Nueva ruta (ej. Lab/mi_curso)';

  @override
  String realmAdminMoveRealmOk(String path) {
    return 'Movido a $path';
  }

  @override
  String get realmAdminMoveRealmFailed =>
      'No se pudo mover (carpeta existente o archivos en uso).';

  @override
  String get realmAdminMoveRealmButton => 'Mover';

  @override
  String get realmAdminShelvesIntro =>
      'Solo un realm activo a la vez (GK lee data/active_realm.txt). Núcleo / Activo / Explorar son estantes de prioridad (no son carpetas físicas).';

  @override
  String realmAdminActiveLine(String id) {
    return 'Activo: $id';
  }

  @override
  String get realmAdminTierHeaderCore => 'Lo más importante / en uso';

  @override
  String get realmAdminTierHeaderActive => 'Realms de trabajo habitual';

  @override
  String get realmAdminTierHeaderSeek => 'Cola larga y experimentación';

  @override
  String get realmAdminEmptyTier => 'Vacío';

  @override
  String get realmAdminFolderIntro =>
      'Lista lo que hay en disco bajo data/realms/ de la raíz resuelta (no es «inventado»). Realm = carpeta con alexandria.db. Mover muchas carpetas: mejor con apps cerradas si la DB está en uso.';

  @override
  String get realmAdminRepoRootCaption =>
      'Raíz del repo (env ALEXANDRIA_ROOT, o búsqueda desde el .exe, o C:\\\\Alexandria si tiene data/realms):';

  @override
  String get realmAdminRealmsFolderCaption =>
      'Carpeta realms (debe coincidir con lo que abre el explorador):';

  @override
  String get realmAdminFolderEmpty => 'Carpeta vacía.';

  @override
  String get realmAdminLeafFolderWithoutDb =>
      'Carpeta sin alexandria.db ni subcarpetas';

  @override
  String get realmAdminRootGroupLabel => 'Raíz (sin subcarpeta)';

  @override
  String get realmAdminDataRealmsChip => 'data/realms';

  @override
  String realmAdminShelfLabel(String tier) {
    return 'Estante: $tier';
  }

  @override
  String get objectSearchUsageCaption =>
      'Vistas por uso: Núcleo · Activo · Explorar (mismos loci; no cambia estructura).';

  @override
  String realmAdminExplorerMissingFolder(String root, String path) {
    return 'Esa carpeta no existe en disco.\nRaíz resuelta: $root\nRuta intentada:\n$path';
  }

  @override
  String realmAdminExplorerError(String error, String path) {
    return 'Explorador: $error\n$path';
  }

  @override
  String realmAdminFolderMissing(String path) {
    return 'Carpeta inexistente:\n$path';
  }

  @override
  String realmAdminOpenFailed(String error) {
    return 'No se pudo abrir: $error';
  }

  @override
  String get realmAdminEmptyFolderDialogTitle => 'Carpeta vacía';

  @override
  String realmAdminEmptyFolderBody(String path) {
    return 'Solo organización (sin alexandria.db). Se crea bajo:\n$path';
  }

  @override
  String get realmAdminEmptyFolderNameLabel => 'Nombre de carpeta';

  @override
  String get realmAdminEmptyFolderNameHint => 'ej. Lab o Clientes_2026';

  @override
  String get realmAdminEmptyFolderNameHelper => 'Un segmento; sin /';

  @override
  String get realmAdminSnackbarSingleSegment => 'Usa un solo nombre sin /';

  @override
  String get realmAdminSnackbarSubfolderCreateFailed =>
      'No se pudo crear (¿ya existe un realm con DB ahí, o nombre inválido?).';

  @override
  String get realmAdminSnackbarFolderCreated => 'Carpeta creada';

  @override
  String get realmDialogNewTitle => 'Nuevo realm';

  @override
  String get realmDialogFolderOptionalLabel => 'Carpeta opcional';

  @override
  String get realmDialogFolderHint => 'ej. Lab o Clientes/2026';

  @override
  String get realmDialogFolderHelper =>
      'Bajo data/realms/; vacío = raíz. En Carpetas se rellena con la vista actual.';

  @override
  String get realmDialogIdLabel => 'Id del realm';

  @override
  String get realmDialogIdHint => 'ej. mi_castillo';

  @override
  String get realmDialogIdHelper => 'Un solo nombre; sin /';

  @override
  String get realmDialogTemplateCopyTitle => 'Copiar desde plantilla';

  @override
  String get realmDialogTemplateCopySubtitle =>
      'Duplica DB, bridge, snapshot, assets… de otro realm.';

  @override
  String get realmDialogEmptyTitle => 'Vacío (misma arquitectura)';

  @override
  String get realmDialogEmptySubtitle =>
      'Mismo árbol fijo (20 parcours + 400 objetos bajo PARCOUR_MAIN), pero sin texto en loci, sin recall/review y assets vacío.';

  @override
  String get realmDialogTemplateLabel => 'Plantilla';

  @override
  String get realmDialogCreate => 'Crear';

  @override
  String get realmDialogIdInvalidChars =>
      'El id del realm no puede contener / ni \\.';

  @override
  String get realmSnackbarCreateEmptyFailed =>
      'No se pudo crear vacío (¿ruta duplicada o error al escribir?).';

  @override
  String get realmSnackbarDuplicateFailed =>
      'No se pudo copiar (¿plantilla inexistente, ruta duplicada?).';

  @override
  String realmSnackbarActiveRealm(String id) {
    return 'Realm activo: $id';
  }

  @override
  String get realmAdminNuclearTitle => 'Borrar toda la data';

  @override
  String get realmAdminNuclearDialogIntro =>
      'Se eliminarán todos los realms, assets, bridge, snapshots, manifests, PAO bajo data/pao y el estante realm_shelf.json.\n\nQuedará solo una base nueva en:\ndata/realms/default/alexandria.db\n\nSe escribirá también el snapshot realm seed en:\ndata/realm_seed/alexandria.db\n\nRealm activo: default.\n\nCierra GateKeeper si está abierto (bloqueo de archivos).\n\nPara confirmar, escribe exactamente:';

  @override
  String get realmAdminConfirmLabel => 'Confirmación';

  @override
  String get realmAdminPhraseMismatch => 'La frase no coincide exactamente.';

  @override
  String get realmAdminNuclearButton => 'Borrar todo';

  @override
  String get realmAdminNuclearSuccessSnackbar =>
      'Data borrada: default/alexandria.db + data/realm_seed/alexandria.db. Ejecuta Library build o reabre la app para regenerar snapshot/viewer.';

  @override
  String get realmSeedDialogTitle => 'Crear realm seed';

  @override
  String realmSeedDialogBody(String realm) {
    return 'Se sanitizará el realm activo ($realm), se ejecutará Library build y se copiará la DB a:\ndata/realm_seed/alexandria.db\n\nCierra GateKeeper si está abierto.';
  }

  @override
  String get realmSeedConfirm => 'Crear';

  @override
  String get realmSeedSavedSnackbar =>
      'Realm seed guardado: data/realm_seed/alexandria.db';

  @override
  String get realmSeedErrorPrefix => 'Realm seed:';

  @override
  String get objectSearchTitle => 'Buscar objetos (FTS5)';

  @override
  String get objectSearchHint => 'Título o texto del locus…';

  @override
  String get objectSearchCardReaderTooltip =>
      'Lector tipo tarjeta (toda la info)';

  @override
  String get objectSearchNoObjects => 'No hay objetos en la base.';

  @override
  String get objectSearchNoMatches => 'Sin coincidencias.';
}
