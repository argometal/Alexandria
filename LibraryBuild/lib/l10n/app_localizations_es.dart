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
  String get librarySurfaceRealmTree => 'Árbol del realm';

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
  String get dataTransferAppBarTitle => 'Data transfer → LibraryBuild';

  @override
  String get dataTransferRefreshTooltip => 'Refrescar archivos y estado';

  @override
  String dataTransferServerRepoLabel(String path) {
    return 'Servidor en repo: $path';
  }

  @override
  String get dataTransferStartServer => 'Iniciar servidor (node)';

  @override
  String get dataTransferStopLbProcess => 'Detener proceso LB';

  @override
  String get dataTransferOpenWebUi => 'Abrir UI web (:4020)';

  @override
  String dataTransferServerReachable(int port) {
    return 'Servidor accesible en http://127.0.0.1:$port';
  }

  @override
  String get dataTransferHealthNoResponse =>
      'Sin respuesta en /health (inicia node o usa solo import local)';

  @override
  String get dataTransferImportHeading => 'Importar archivo a un locus';

  @override
  String dataTransferImportHint(String folder) {
    return 'Origen: $folder · Si el contenido empieza por [ se interpreta como JSON de bloques; si no, se crea un único párrafo. Modo «Añadir» concatena bloques al body existente.';
  }

  @override
  String get dataTransferFolderLabelOut => 'out/';

  @override
  String get dataTransferFolderLabelIncoming => 'handoff/incoming/';

  @override
  String get dataTransferNoObjects => 'No hay entradas object en la DB.';

  @override
  String get dataTransferTargetLocus => 'Locus destino (object)';

  @override
  String dataTransferLocusDropdownLine(
    String key,
    String title,
    String parentKey,
  ) {
    return '$key — $title (parent: $parentKey)';
  }

  @override
  String get dataTransferFileFolder => 'Carpeta de archivos';

  @override
  String get dataTransferSegmentOut => 'out/';

  @override
  String get dataTransferSegmentIncoming => 'incoming/';

  @override
  String dataTransferFileCounts(int outCount, int incomingCount) {
    return 'out/: $outCount · incoming/: $incomingCount';
  }

  @override
  String get dataTransferOutFolderEmpty =>
      'Carpeta out/ vacía. Usa la UI web, o cambia a incoming/, o copia ficheros en data-transfer/out/.';

  @override
  String get dataTransferIncomingFolderEmpty =>
      'Carpeta handoff/incoming/ vacía. Copia aquí archivos o usa out/.';

  @override
  String dataTransferFilePickerLabel(String folder) {
    return 'Archivo ($folder)';
  }

  @override
  String get dataTransferImportMode => 'Modo de importación';

  @override
  String get dataTransferReplaceBody => 'Reemplazar body';

  @override
  String get dataTransferAppendBlocks => 'Añadir al final';

  @override
  String get dataTransferImportRunBuild =>
      'Importar al locus y runLibraryBuild';

  @override
  String dataTransferScriptMissing(String path) {
    return 'No existe $path';
  }

  @override
  String get dataTransferServerAlreadyRunning =>
      'Ya hay un servidor en :4020 (externo u otro proceso)';

  @override
  String get dataTransferNodeStartedNoHealth =>
      'Proceso node iniciado pero /health no responde. ¿Node en PATH?';

  @override
  String dataTransferNodeStartFailed(String error) {
    return 'No se pudo iniciar node: $error';
  }

  @override
  String dataTransferOpenUrlFailed(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get dataTransferPickFileAndLocus => 'Elige archivo y locus destino.';

  @override
  String dataTransferImportDoneReplace(String key, String file) {
    return 'Reemplazo · $key ($file)';
  }

  @override
  String dataTransferImportDoneAppend(String key, String file) {
    return 'Añadido al final · $key ($file)';
  }

  @override
  String dataTransferErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String dataTransferHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get paoEditorTitle => 'PAO';

  @override
  String get paoEditorSubtitle =>
      'Claves fonéticas · clavijas 0–9 · 00–99 · 000–999 · JSON';

  @override
  String get paoTabPhonetic => 'Claves';

  @override
  String get paoTabDigit => '0–9';

  @override
  String get paoTabPair => '00–99';

  @override
  String get paoTabTriple => '000–999';

  @override
  String get paoPhoneticBoardHint =>
      'Asigna consonantes o sonidos a cada dígito (tu variante del sistema Mayor). Las vocales son rellenos; la columna opcional es solo para notas.';

  @override
  String get paoPhoneticConsonantsLabel => 'Consonantes / sonidos';

  @override
  String get paoPhoneticVowelNoteLabel => 'Notas vocales (opcional)';

  @override
  String get paoPhoneticSaveRow => 'Guardar';

  @override
  String get paoPhoneticSaved => 'Fila guardada';

  @override
  String get paoSearchHint =>
      'Buscar por código, persona, acción, objeto o ruta de imagen';

  @override
  String paoSubtitleTier(int filled, int total, String realm) {
    return '$filled / $total con texto o imagen · realm $realm';
  }

  @override
  String get paoMenuImportJsonAuto =>
      'Importar JSON (auto: v2 completo o legado 00–99)';

  @override
  String get paoMenuExportJsonV2 => 'Exportar JSON (v2 completo)…';

  @override
  String get paoMenuExportPairCsv => 'Exportar CSV (solo 00–99)…';

  @override
  String get paoMenuTemplateV2 => 'Escribir plantilla v2 vacía en el repo';

  @override
  String get paoSnackbarImportOk => 'Datos PAO importados';

  @override
  String paoSnackbarTemplateV2(String path) {
    return 'Plantilla v2 escrita: $path';
  }

  @override
  String get paoEditCodeImageHintPair =>
      'Imagen del código (00–99): arrastra o Ctrl/Cmd+V con el foco fuera de los campos de texto.';

  @override
  String get paoEditCodeImageHintDigit =>
      'Imagen del código (un dígito): arrastra o Ctrl/Cmd+V con el foco fuera de los campos de texto.';

  @override
  String get paoEditCodeImageHintTriple =>
      'Imagen del código (000–999): arrastra o Ctrl/Cmd+V con el foco fuera de los campos de texto.';

  @override
  String get paoEditPreviewExerciseTooltip => 'Vista previa del ejercicio';

  @override
  String get paoEditPreviewExerciseTitle => 'Vista previa (práctica)';

  @override
  String get paoEditPreviewExerciseIntro =>
      'Cómo puede verse esta clavija en la práctica individual (estímulos del drill y panel de respuestas).';

  @override
  String get paoPracticeTitle => 'PAO · práctica individual';

  @override
  String get paoPracticeSubtitle =>
      'Recall mental · mostrar respuestas · acierto/fallo';

  @override
  String get paoDrillInstruction =>
      'Recuerda en silencio; no escribas. Luego muestra las respuestas y marca acierto o fallo.';

  @override
  String get paoDrillModeCodeTitle =>
      'Código → persona, acción, objeto (mental)';

  @override
  String get paoDrillModePersonTitle =>
      'Persona → código, acción, objeto (mental)';

  @override
  String get paoDrillModeObjectTitle =>
      'Objeto → código, persona, acción (mental)';

  @override
  String paoDrillPoolInfo(int count, String realmId) {
    return '$count códigos · realm $realmId';
  }

  @override
  String get paoDrillShowAnswers => 'Mostrar respuestas';

  @override
  String get paoDrillAnswersHeading => 'Respuestas';

  @override
  String get paoFieldCode => 'Código';

  @override
  String get paoFieldPerson => 'Persona';

  @override
  String get paoFieldAction => 'Acción';

  @override
  String get paoFieldObject => 'Objeto';

  @override
  String get paoDrillSuccess => 'Acierto';

  @override
  String get paoDrillFail => 'Fallo';

  @override
  String get paoDrillNextUnmarked => 'Siguiente (sin marcar)';

  @override
  String get paoDrillEmptyTitle => 'No hay códigos listos para practicar.';

  @override
  String get paoDrillEmptyHint =>
      'Rellena persona, acción y objeto en al menos un código en PAO (dígito, par 00–99 o triple 000–999).';

  @override
  String get paoDrillStimulusCode => 'Código';

  @override
  String get paoDrillStimulusPerson => 'Persona';

  @override
  String get paoDrillStimulusObject => 'Objeto';

  @override
  String get paoDrillStimulusRecallNumber => 'Recuerda el número';

  @override
  String get paoDrillStimulusRecallMnemonic => 'Recuerda la imagen (mnemónico)';

  @override
  String get paoDrillPoolAllTiersHint =>
      'Mazo: códigos aleatorios de 0–9, 00–99 y 000–999 (filas completas). En cada ronda solo ves el número o la imagen del código — no ambos.';

  @override
  String get paoListEmptyRow => '(vacío)';

  @override
  String paoListDetailLine(String person, String action, String object) {
    return 'P: $person  |  A: $action  |  O: $object';
  }

  @override
  String get paoEditChooseImage => 'Elegir imagen';

  @override
  String get paoEditRemoveImage => 'Quitar';

  @override
  String get paoEditNoImageOptional => 'Sin imagen (opcional)';

  @override
  String get paoEditImageLoadError => 'No se puede cargar la imagen';

  @override
  String get paoEditPersonImage1 => 'Imagen personaje 1';

  @override
  String get paoEditPersonImage2 => 'Imagen personaje 2';

  @override
  String get paoEditObjectImage1 => 'Imagen objeto 1';

  @override
  String get paoEditObjectImage2 => 'Imagen objeto 2';

  @override
  String get paoEditPasteImageTooltip => 'Pegar imagen (Ctrl+V en esta ranura)';

  @override
  String get paoTemplateExistsTitle => 'La plantilla ya existe';

  @override
  String paoTemplateExistsBody(String path) {
    return '¿Sobrescribir?\n$path';
  }

  @override
  String get paoOverwrite => 'Sobrescribir';

  @override
  String paoTemplateWritten0099(String path) {
    return 'Plantilla escrita: $path';
  }

  @override
  String get paoExportJsonDialogTitle => 'Exportar PAO JSON v2';

  @override
  String get paoExportCsvDialogTitle => 'Exportar PAO CSV';

  @override
  String paoSavedToPath(String path) {
    return 'Guardado: $path';
  }

  @override
  String paoErrorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get paoJsonV2CopiedClipboard => 'JSON PAO v2 copiado al portapapeles';

  @override
  String get paoMenuTemplate0099 => 'Plantilla 00–99 (repo)';

  @override
  String get paoMenuCopyJsonV2Clipboard => 'Copiar JSON v2 al portapapeles';

  @override
  String get paoSnackbarPasteImageUseTabs =>
      'Pegar imagen: usa las pestañas 0–9, 00–99 o 000–999 y toca una fila.';

  @override
  String get paoSnackbarTapRowFirst =>
      'Toca primero una fila para elegir el código.';

  @override
  String get paoSnackbarCodeNotInTab => 'Código no encontrado en esta pestaña.';

  @override
  String get paoSnackbarClipboardNoImage => 'Portapapeles: no hay imagen';

  @override
  String get paoSnackbarCouldNotSaveImage => 'No se pudo guardar la imagen';

  @override
  String get paoSnackbarCouldNotCopyImage => 'No se pudo copiar la imagen';

  @override
  String paoSnackbarCodeImageUpdated(String code) {
    return 'Imagen del código $code actualizada';
  }

  @override
  String get paoSnackbarDropImageUseTabs =>
      'Suelta la imagen en pestañas 0–9, 00–99 o 000–999 (tras tocar una fila).';

  @override
  String paoEditDialogTitle(String code) {
    return 'PAO $code';
  }

  @override
  String get paoEditDeletePegButton => 'Borrar clavija';

  @override
  String get paoEditDeletePegConfirmTitle => '¿Borrar esta clavija?';

  @override
  String get paoEditDeletePegConfirmBody =>
      'Se eliminan persona, acción, objeto y todas las imágenes de este código, y se borran los archivos en la carpeta de assets del realm.';

  @override
  String get paoEditDeletePegSuccess => 'Clavija vaciada';

  @override
  String get pokerMemoryTitle => 'Póker · mapa numérico';

  @override
  String get pokerMemoryDrawerSubtitle =>
      'Número ↔ carta · 13 números por palo · práctica rápida';

  @override
  String get frameRecallQuizDrawerSubtitle =>
      'Quiz de 4 recortes · mismo parcour';

  @override
  String get frameRecallQuizTitle => 'Recall de marco (prototipo)';

  @override
  String get frameRecallQuizIntro =>
      'Cada locus necesita un bloque imagen con rol «Recall crop» (detalle del hero). Aquí no se muestra el hero — solo la pista [place] y cuatro recortes. Elige el recorte que corresponde al locus descrito.';

  @override
  String get frameRecallSelectParcour => 'Parcour';

  @override
  String frameRecallFramesWithCrop(int count) {
    return '$count marcos con recorte recall';
  }

  @override
  String get frameRecallNeedFour =>
      'Hacen falta al menos 4 loci en este parcour con imagen «Recall crop». Edita cada locus y añade una imagen con ese rol.';

  @override
  String get frameRecallNoParcours =>
      'No hay parcours bajo el hub. Crea parcours primero.';

  @override
  String get frameRecallQuestion => 'Place / pista';

  @override
  String get frameRecallLocusLabel => 'Locus';

  @override
  String get frameRecallPickCrop => '¿Qué recorte corresponde?';

  @override
  String get frameRecallCorrect => 'Correcto.';

  @override
  String get frameRecallWrong =>
      'Incorrecto — el borde verde es el recorte correcto.';

  @override
  String get frameRecallNext => 'Siguiente pregunta';

  @override
  String frameRecallMissingFile(String name) {
    return 'Falta archivo: $name';
  }

  @override
  String get pokerMemoryTabMap => 'Mapa';

  @override
  String get pokerMemoryTabRanges => 'Rangos';

  @override
  String get pokerMemoryTabDrill => 'Práctica rápida';

  @override
  String get pokerMemoryMapIntro =>
      'Cada número corresponde a una carta (A, 2–10, J, Q, K dentro del bloque del palo). Edita los rangos en la pestaña Rangos.';

  @override
  String get pokerMemoryMapEmpty =>
      'Sin mapeos. Revisa los rangos (cada palo: exactamente 13 números, sin solapes).';

  @override
  String get pokerMemoryRangesIntro =>
      'Asigna un bloque continuo de 13 números por palo. Por defecto: espadas 01–13, corazones 41–53, diamantes 61–73, tréboles 81–93.';

  @override
  String get pokerMemoryRangeFrom => 'Desde';

  @override
  String get pokerMemoryRangeTo => 'Hasta';

  @override
  String get pokerMemoryRangesSave => 'Guardar rangos';

  @override
  String get pokerMemoryRangesSaved => 'Rangos guardados';

  @override
  String get pokerMemoryRangesInvalidNumber =>
      'Introduce enteros válidos en desde / hasta.';

  @override
  String get pokerMemoryRangesHint =>
      'Los rangos siguen el orden A, 2, 3, …, 10, J, Q, K. Pueden quedar huecos entre palos.';

  @override
  String get pokerMemorySuitSpades => 'Espadas';

  @override
  String get pokerMemorySuitHearts => 'Corazones';

  @override
  String get pokerMemorySuitDiamonds => 'Diamantes';

  @override
  String get pokerMemorySuitClubs => 'Tréboles';

  @override
  String get pokerMemoryDrillInstruction =>
      'Recuerda mentalmente la otra cara; luego muestra la respuesta y marca acierto o fallo.';

  @override
  String get pokerMemoryDrillModeNumberToCard => 'Número → carta';

  @override
  String get pokerMemoryDrillModeCardToNumber => 'Carta → número';

  @override
  String pokerMemoryDrillPoolInfo(int count, String realmId) {
    return '$count cartas · realm $realmId';
  }

  @override
  String get pokerMemoryStimulusNumber => 'Número';

  @override
  String get pokerMemoryStimulusCard => 'Carta';

  @override
  String get pokerMemoryShowAnswer => 'Mostrar respuesta';

  @override
  String get pokerMemoryAnswerHeading => 'Respuesta';

  @override
  String get pokerMemoryAnswerNumber => 'Número';

  @override
  String get pokerMemoryAnswerCard => 'Carta';

  @override
  String get pokerMemoryPass => 'Acierto';

  @override
  String get pokerMemoryFail => 'Fallo';

  @override
  String get pokerMemoryNext => 'Siguiente';

  @override
  String get pokerMemoryDrillEmpty =>
      'No hay práctica posible. Corrige los rangos.';

  @override
  String get matchCardsTitle => 'Cartas (emparejar)';

  @override
  String get matchCardsSubtitle => 'Imagen ↔ pie · sesión aleatoria (solo LB)';

  @override
  String get matchCardsOrmHint =>
      'Cada par: lema (escritura nativa), transliteración opcional, significado (gloss) opcional e imagen. route_key es para un futuro «por ruta». Las sesiones eligen cartas por paso Fibonacci (intervalo más corto primero) y luego por más fallos acumulados.';

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
  String get matchCardsSessionMenuTooltip => 'Sesión';

  @override
  String get matchCardsSessionNewRound => 'Nueva ronda';

  @override
  String get matchCardsSessionChangeDeck => 'Cambiar mazo…';

  @override
  String get matchCardsSessionStats => 'Cartas más flojas…';

  @override
  String get matchCardsSessionStatsTitle => 'Estadísticas del mazo';

  @override
  String get matchCardsSessionStatsSubtitle =>
      'Las rondas priorizan el paso Fibonacci más bajo (necesita práctica) y luego más fallos acumulados. Cada emparejamiento incorrecto suma fallo en ambas cartas.';

  @override
  String get matchCardsSessionStatsEmpty =>
      'Aún no hay datos — juega varias rondas para ver contadores.';

  @override
  String matchCardsSessionStatsFailPass(int fails, int passes) {
    return '$fails fallos · $passes aciertos';
  }

  @override
  String matchCardsSessionStatsFib(int n) {
    return 'Paso $n';
  }

  @override
  String matchCardsDeckOverviewKpis(
    int pairCount,
    int dueCount,
    String matchRate,
  ) {
    return '$pairCount pares · $dueCount pendientes de repaso · aciertos $matchRate';
  }

  @override
  String get matchCardsDeckOverviewFibBars =>
      'Pares por paso Fibonacci (altura de barra)';

  @override
  String get matchCardsSessionPickDeckTitle => 'Elegir mazo';

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
  String goGameScoreSummary(
    String blackPt,
    String whiteBoardPt,
    String komi,
    String whiteTotal,
    String verdict,
  ) {
    return 'Negras $blackPt pt — Blancas $whiteBoardPt en tablero + $komi komi = $whiteTotal pt. $verdict';
  }

  @override
  String get goGameVerdictDraw => 'Empate.';

  @override
  String goGameVerdictBlackWins(String margin) {
    return 'Ganan negras por $margin pt.';
  }

  @override
  String goGameVerdictWhiteWins(String margin) {
    return 'Ganan blancas por $margin pt.';
  }

  @override
  String goGameStoneTotals(int blackStones, int whiteStones) {
    return 'Piedras en el tablero: negras $blackStones · blancas $whiteStones';
  }

  @override
  String get goStudyTabFree => 'Partida libre';

  @override
  String get goStudyTabProblems => 'Problemas';

  @override
  String get goStudyLibraryTooltip => 'Biblioteca de problemas y progreso';

  @override
  String get goStudyLibraryTitle => 'Problemas de Go';

  @override
  String goStudyLibraryLine(int solved, int mastered) {
    return '$solved resueltos · $mastered estudiados (3+ aciertos)';
  }

  @override
  String get goStudyMasteredLabel => 'Estudiado';

  @override
  String get goStudySolvedLabel => 'Resuelto una vez';

  @override
  String goStudyAttemptsLabel(int n) {
    return '$n intentos';
  }

  @override
  String get goStudyProblemWrong =>
      'No es la jugada buscada — prueba otra vez.';

  @override
  String get goStudyProblemCorrect => '¡Correcto!';

  @override
  String get goStudyHint => 'Pista';

  @override
  String get goStudyShowLegal => 'Jugadas legales';

  @override
  String goStudyProblemIndex(int current, int total) {
    return 'Problema $current / $total';
  }

  @override
  String get goStudyNextProblem => 'Siguiente';

  @override
  String get goStudyPrevProblem => 'Anterior';

  @override
  String get goStudyResetProblem => 'Reiniciar posición';

  @override
  String get goStudyPassDisabled => 'Pasar está desactivado en este modo.';

  @override
  String get goStudyBotDisabled => 'El bot se desactiva en problemas.';

  @override
  String get goProblemCapTitle => 'Captura (atari)';

  @override
  String get goProblemCapHint => 'Quita la última libertad de la blanca.';

  @override
  String get goProblemConnectTitle => 'Conectar (lado)';

  @override
  String get goProblemConnectHint => 'Juega entre las dos negras.';

  @override
  String get goProblemBridgeTitle => 'Conectar (arriba/abajo)';

  @override
  String get goProblemBridgeHint => 'Une las dos negras en la misma columna.';

  @override
  String get metricsRecallTitle => 'Métricas recall';

  @override
  String get metricsRecallSubtitle => 'Exportar CSV';

  @override
  String get realmsTitle => 'Reinos';

  @override
  String get realmsSubtitle => 'Núcleo · Activo · Explorar';

  @override
  String get navigationIntentTitle => 'Navegación de estudio';

  @override
  String get navigationIntentTooltip =>
      'Toca para cambiar de modo. Con un objeto enfocado, la línea 2 del bridge es la clave del marco Hero para place / hint / historia.';

  @override
  String get memoryAthleteSwitchTitle =>
      'Aprobación parcour: 100% (atleta) vs 80% (estándar)';

  @override
  String get memoryAthleteSwitchSubtitleOn =>
      'Activado — se exige aprobación completa (100% de la puntuación de sesión).';

  @override
  String get memoryAthleteSwitchSubtitleOff =>
      'Desactivado — aprobar con al menos el 80% de la puntuación (estándar).';

  @override
  String get studyNavigationTitle => 'Navegación de estudio';

  @override
  String get studyNavigationTooltip =>
      'Toca para cambiar de modo. El subtítulo indica modo y clave del marco Hero.';

  @override
  String studyNavigationDetailModeOnly(String mode) {
    return 'Modo: $mode';
  }

  @override
  String studyNavigationDetailWithFrame(String mode, String frame) {
    return 'Modo: $mode\nMarco (Hero locus): $frame';
  }

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
    return 'Modo → $mode$frameSuffix (HUD visor 3D)';
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
  String get parcourFibDueReady => 'due';

  @override
  String parcourFibDueInDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count días',
      one: 'en 1 día',
    );
    return '$_temp0';
  }

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
  String get locusEditorSaved => 'Guardado';

  @override
  String locusEditorSubtitleLine(String role, String turn) {
    return '$role · $turn';
  }

  @override
  String get locusEditorHelpMenuLabel => 'Ayuda del editor de locus';

  @override
  String get locusEditorHelpMenuSubtitle =>
      'Qué puedes hacer aquí y cómo se sincroniza con GateKeeper';

  @override
  String get locusEditorHelpDialogTitle => 'Uso del editor de locus';

  @override
  String get locusEditorDeleteMenuLabel => 'Eliminar este locus';

  @override
  String get placeRecallDrawerTitle => 'Place recall';

  @override
  String get placeRecallDrawerSubtitle =>
      'Activa el gate de recortes en el visor 3D (o usa el modo de estudio place_recall). Requiere assets recall_crop; los distractores salen de hermanos del parcour cuando hay suficientes.';

  @override
  String get locusEditorDeleteMenuSubtitle =>
      'Quita esta entrada y sus descendientes de la base de datos y archivos del realm; no borra el archivo entero de la DB.';

  @override
  String get locusEditorDeleteConfirmTitle =>
      'Eliminar locus de forma permanente';

  @override
  String locusEditorDeleteConfirmDescription(String realmPath) {
    return 'Elimina esta entrada y todos los descendientes de la base de datos del realm ($realmPath), borra filas relacionadas en tablas de revisión/parcour, quita archivos de assets/snapshot/viewer/manifest para esas claves y reconstruye snapshots.';
  }

  @override
  String locusEditorDeleteConfirmDeletingLabel(String key) {
    return 'Se eliminará: $key';
  }

  @override
  String get locusEditorDeleteConfirmTypeInstruction =>
      'Se borrará el locus indicado arriba. Para confirmar, escribe en el campo la frase siguiente exactamente; no es la clave interna. Respeta espacios y mayúsculas:';

  @override
  String get locusEditorDeleteConfirmPhraseExact => 'Delete Node';

  @override
  String get locusEditorDeleteConfirmFieldHint => 'Delete Node';

  @override
  String get locusEditorDeleteConfirmButton => 'Eliminar';

  @override
  String get locusEditorHelpDialogBody =>
      'Aquí editas una entrada del realm: bloques de texto, enlaces, imágenes y tarjetas de vocabulario.\n\nRol cognitivo — Realm (contenedor), Parcour (pasillo de marcos) u Objeto (lo que lees en el visor de GateKeeper). Los hijos bajo un parcour son marcos ordenados en el recorrido 3D.\n\nBloques — Los párrafos pueden ser texto normal o tipos de estudio: Lugar, Pista, Historia ridícula. Las imágenes eligen rol: Contenido (solo visor), Collage (paneles en la pared de GateKeeper entre marcos) o Hero (la imagen del marco 3D). Hero rápido: enfoca un bloque imagen y pulsa Ctrl/Cmd+H.\n\nTarjetas — Palabra o lema, ilustración y audio bajo assets de esta clave, archivo opcional de fonética y claves relacionadas que ya existan en el realm.\n\nGiro espacial — Para entradas hijas directas de un parcour, indica cómo sigue el pasillo hacia el siguiente marco (recto, izquierda, derecha).\n\nPlace recall — En objetos, activa place recall si quieres el drill en GateKeeper. Añade una imagen con rol Recall crop; el drill necesita este marco y otros tres objetos del realm con recall_crop válidos.\n\nPegar y archivos — Pega texto o imágenes con Ctrl+V / Cmd+V cuando el foco no esté dentro de un campo de texto. En escritorio, suelta .png / .jpg / .webp en la zona de destino.\n\nGuardar — Escribe la base de datos, copia assets y actualiza visor y snapshots para que GateKeeper pueda recargar.';

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
  String get realmAdminTooltipNuclear =>
      'Limpiar bibliotecas de realm (irreversible) — PAO y Match cards se conservan';

  @override
  String get realmAdminCleanupMenuTooltip => 'Limpiar solo PAO o Match cards';

  @override
  String get realmAdminCleanPaoTitle => 'Limpiar datos PAO';

  @override
  String get realmAdminCleanPaoBody =>
      'Quita filas PAO en la base del realm activo y JSON de usuario en data/pao/ (se mantienen plantillas *.template). No toca el árbol del realm ni Match cards.';

  @override
  String get realmAdminCleanPaoConfirm => 'Limpiar PAO';

  @override
  String get realmAdminCleanPaoSnackbar => 'Datos PAO limpiados.';

  @override
  String get realmAdminCleanMatchTitle => 'Limpiar datos Match cards';

  @override
  String get realmAdminCleanMatchBody =>
      'Borra mazos, pares, estado de repaso e imágenes en assets/lb_match_cards/ del realm activo. Irreversible.';

  @override
  String get realmAdminCleanMatchConfirm => 'Limpiar Match cards';

  @override
  String get realmAdminCleanMatchSnackbar => 'Datos Match cards limpiados.';

  @override
  String get realmAdminMatchCardsTileTitle => 'Match cards';

  @override
  String get realmAdminMatchCardsTileSubtitle =>
      'Mazos y pares imagen–texto del realm activo. Abre la vista Match cards en el inicio de la biblioteca.';

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
      'Se eliminarán todas las carpetas bajo data/realms/ (assets, bridge, snapshots, manifests, realm_shelf.json). La carpeta data/pao/ del repo no se borra.\n\nLos datos PAO y Match cards del realm activo se copian a la nueva base default y assets.\n\nQuedará solo una base nueva en:\ndata/realms/default/alexandria.db\n\nTambién se escribirá el snapshot realm seed en:\ndata/realm_seed/alexandria.db\n\nRealm activo: default.\n\nCierra el visor 3D si está abierto (bloqueo de archivos).\n\nPara confirmar, escribe exactamente:';

  @override
  String get realmAdminConfirmLabel => 'Confirmación';

  @override
  String get realmAdminPhraseMismatch => 'La frase no coincide exactamente.';

  @override
  String get realmAdminNuclearButton => 'Borrar todo';

  @override
  String get realmAdminNuclearSuccessSnackbar =>
      'Bibliotecas de realm limpiadas; PAO y Match cards restaurados en default. default/alexandria.db + data/realm_seed/alexandria.db. Ejecuta Library build o reabre la app para regenerar snapshot/viewer.';

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
