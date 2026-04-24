// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Biblioteca de realms';

  @override
  String get librarySurfaceRealmTree => 'Árvore do realm';

  @override
  String activeRealmLabel(String realm) {
    return 'Realm ativo: $realm';
  }

  @override
  String get sectionReading => 'LEITURA';

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
  String get nodeReaderTitle => 'Leitor de nó';

  @override
  String get nodeReaderSubtitle => 'Parcour ou objeto (lista)';

  @override
  String get pdfNodeTitle => 'PDF do nó';

  @override
  String get pdfNodeSubtitle => 'Objeto ou outra entrada';

  @override
  String get pdfParcourTitle => 'PDF do parcour';

  @override
  String get pdfParcourSubtitle => 'Um parcour por exportação';

  @override
  String get importLocusTitle => 'Importar conteúdo para o locus';

  @override
  String get importLocusSubtitle => 'De data-transfer/out/ → body_text';

  @override
  String get dataTransferAppBarTitle => 'Data transfer → LibraryBuild';

  @override
  String get dataTransferRefreshTooltip => 'Atualizar ficheiros e estado';

  @override
  String dataTransferServerRepoLabel(String path) {
    return 'Servidor no repositório: $path';
  }

  @override
  String get dataTransferStartServer => 'Iniciar servidor (node)';

  @override
  String get dataTransferStopLbProcess => 'Parar processo LB';

  @override
  String get dataTransferOpenWebUi => 'Abrir UI web (:4020)';

  @override
  String dataTransferServerReachable(int port) {
    return 'Servidor acessível em http://127.0.0.1:$port';
  }

  @override
  String get dataTransferHealthNoResponse =>
      'Sem resposta em /health (inicie o node ou use só import local)';

  @override
  String get dataTransferImportHeading => 'Importar ficheiro para um locus';

  @override
  String dataTransferImportHint(String folder) {
    return 'Origem: $folder · Se o conteúdo começar por [ é interpretado como JSON de blocos; caso contrário cria-se um único parágrafo. O modo «Adicionar» concatena blocos ao body existente.';
  }

  @override
  String get dataTransferFolderLabelOut => 'out/';

  @override
  String get dataTransferFolderLabelIncoming => 'handoff/incoming/';

  @override
  String get dataTransferNoObjects =>
      'Não há entradas object na base de dados.';

  @override
  String get dataTransferTargetLocus => 'Locus de destino (object)';

  @override
  String dataTransferLocusDropdownLine(
    String key,
    String title,
    String parentKey,
  ) {
    return '$key — $title (parent: $parentKey)';
  }

  @override
  String get dataTransferFileFolder => 'Pasta de ficheiros';

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
      'A pasta out/ está vazia. Use a UI web, mude para incoming/ ou copie ficheiros para data-transfer/out/.';

  @override
  String get dataTransferIncomingFolderEmpty =>
      'A pasta handoff/incoming/ está vazia. Copie ficheiros para aqui ou use out/.';

  @override
  String dataTransferFilePickerLabel(String folder) {
    return 'Ficheiro ($folder)';
  }

  @override
  String get dataTransferImportMode => 'Modo de importação';

  @override
  String get dataTransferReplaceBody => 'Substituir body';

  @override
  String get dataTransferAppendBlocks => 'Adicionar no fim';

  @override
  String get dataTransferImportRunBuild =>
      'Importar para o locus e runLibraryBuild';

  @override
  String dataTransferScriptMissing(String path) {
    return 'Ficheiro em falta: $path';
  }

  @override
  String get dataTransferServerAlreadyRunning =>
      'Já existe um servidor a escutar em :4020 (externo ou outro processo)';

  @override
  String get dataTransferNodeStartedNoHealth =>
      'Processo node iniciado mas /health não responde. Node no PATH?';

  @override
  String dataTransferNodeStartFailed(String error) {
    return 'Não foi possível iniciar o node: $error';
  }

  @override
  String dataTransferOpenUrlFailed(String url) {
    return 'Não foi possível abrir $url';
  }

  @override
  String get dataTransferPickFileAndLocus =>
      'Escolha um ficheiro e o locus de destino.';

  @override
  String dataTransferImportDoneReplace(String key, String file) {
    return 'Substituído · $key ($file)';
  }

  @override
  String dataTransferImportDoneAppend(String key, String file) {
    return 'Anexado · $key ($file)';
  }

  @override
  String dataTransferErrorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String dataTransferHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get paoEditorTitle => 'PAO';

  @override
  String get paoEditorSubtitle =>
      'Chaves fonéticas · estacas 0–9 · 00–99 · 000–999 · JSON';

  @override
  String get paoTabPhonetic => 'Chaves';

  @override
  String get paoTabDigit => '0–9';

  @override
  String get paoTabPair => '00–99';

  @override
  String get paoTabTriple => '000–999';

  @override
  String get paoPhoneticBoardHint =>
      'Atribua consoantes ou sons a cada dígito (sua variante do sistema maior). Vogais são preenchimentos; a coluna opcional é só para notas.';

  @override
  String get paoPhoneticConsonantsLabel => 'Consoantes / sons';

  @override
  String get paoPhoneticVowelNoteLabel => 'Notas de vogais (opcional)';

  @override
  String get paoPhoneticSaveRow => 'Guardar';

  @override
  String get paoPhoneticSaved => 'Linha guardada';

  @override
  String get paoSearchHint =>
      'Pesquisar por código, pessoa, ação, objeto ou caminho da imagem';

  @override
  String paoSubtitleTier(int filled, int total, String realm) {
    return '$filled / $total com texto ou imagem · realm $realm';
  }

  @override
  String get paoMenuImportJsonAuto =>
      'Importar JSON (auto: v2 completo ou legado 00–99)';

  @override
  String get paoMenuExportJsonV2 => 'Exportar JSON (v2 completo)…';

  @override
  String get paoMenuExportPairCsv => 'Exportar CSV (só 00–99)…';

  @override
  String get paoMenuTemplateV2 => 'Escrever modelo v2 vazio no repositório';

  @override
  String get paoSnackbarImportOk => 'Dados PAO importados';

  @override
  String paoSnackbarTemplateV2(String path) {
    return 'Modelo v2 escrito: $path';
  }

  @override
  String get paoEditCodeImageHintPair =>
      'Imagem do código (00–99): arraste ou Ctrl/Cmd+V com foco fora dos campos.';

  @override
  String get paoEditCodeImageHintDigit =>
      'Imagem do código (um dígito): arraste ou Ctrl/Cmd+V com foco fora dos campos.';

  @override
  String get paoEditCodeImageHintTriple =>
      'Imagem do código (000–999): arraste ou Ctrl/Cmd+V com foco fora dos campos.';

  @override
  String get paoEditPreviewExerciseTooltip => 'Pré-visualizar no exercício';

  @override
  String get paoEditPreviewExerciseTitle => 'Pré-visualização (prática)';

  @override
  String get paoEditPreviewExerciseIntro =>
      'Como esta clavija pode aparecer na prática individual (estímulos do drill e painel de respostas).';

  @override
  String get paoPracticeTitle => 'PAO · prática individual';

  @override
  String get paoPracticeSubtitle =>
      'Memória · mostrar respostas · acerto / falha';

  @override
  String get paoDrillInstruction =>
      'Relembra em silêncio; não escrevas. Depois mostra as respostas e marca acerto ou falha.';

  @override
  String get paoDrillModeCodeTitle => 'Código → pessoa, ação, objeto (mental)';

  @override
  String get paoDrillModePersonTitle =>
      'Pessoa → código, ação, objeto (mental)';

  @override
  String get paoDrillModeObjectTitle =>
      'Objeto → código, pessoa, ação (mental)';

  @override
  String paoDrillPoolInfo(int count, String realmId) {
    return '$count códigos · realm $realmId';
  }

  @override
  String get paoDrillShowAnswers => 'Mostrar respostas';

  @override
  String get paoDrillAnswersHeading => 'Respostas';

  @override
  String get paoFieldCode => 'Código';

  @override
  String get paoFieldPerson => 'Pessoa';

  @override
  String get paoFieldAction => 'Ação';

  @override
  String get paoFieldObject => 'Objeto';

  @override
  String get paoDrillSuccess => 'Acerto';

  @override
  String get paoDrillFail => 'Falha';

  @override
  String get paoDrillNextUnmarked => 'Seguinte (sem marcar)';

  @override
  String get paoDrillEmptyTitle => 'Não há códigos prontos para praticar.';

  @override
  String get paoDrillEmptyHint =>
      'Preenche pessoa, ação e objeto em pelo menos um código em PAO (dígito, par 00–99 ou triplo 000–999).';

  @override
  String get paoDrillStimulusCode => 'Código';

  @override
  String get paoDrillStimulusPerson => 'Pessoa';

  @override
  String get paoDrillStimulusObject => 'Objeto';

  @override
  String get paoDrillStimulusRecallNumber => 'Lembra-te do número';

  @override
  String get paoDrillStimulusRecallMnemonic =>
      'Lembra-te da imagem (mnemónico)';

  @override
  String get paoDrillPoolAllTiersHint =>
      'Conjunto: códigos aleatórios de 0–9, 00–99 e 000–999 (linhas completas). Em cada ronda vês só o número ou a imagem do código — não ambos.';

  @override
  String get paoListEmptyRow => '(vazio)';

  @override
  String paoListDetailLine(String person, String action, String object) {
    return 'P: $person  |  A: $action  |  O: $object';
  }

  @override
  String get paoEditChooseImage => 'Escolher imagem';

  @override
  String get paoEditRemoveImage => 'Remover';

  @override
  String get paoEditNoImageOptional => 'Sem imagem (opcional)';

  @override
  String get paoEditImageLoadError => 'Não foi possível carregar a imagem';

  @override
  String get paoEditPersonImage1 => 'Imagem personagem 1';

  @override
  String get paoEditPersonImage2 => 'Imagem personagem 2';

  @override
  String get paoEditObjectImage1 => 'Imagem objeto 1';

  @override
  String get paoEditObjectImage2 => 'Imagem objeto 2';

  @override
  String get paoEditPasteImageTooltip => 'Colar imagem (Ctrl+V neste espaço)';

  @override
  String get paoTemplateExistsTitle => 'O modelo já existe';

  @override
  String paoTemplateExistsBody(String path) {
    return 'Substituir?\n$path';
  }

  @override
  String get paoOverwrite => 'Substituir';

  @override
  String paoTemplateWritten0099(String path) {
    return 'Modelo escrito: $path';
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
    return 'Erro: $message';
  }

  @override
  String get paoJsonV2CopiedClipboard =>
      'JSON PAO v2 copiado para a área de transferência';

  @override
  String get paoMenuTemplate0099 => 'Modelo 00–99 (repositório)';

  @override
  String get paoMenuCopyJsonV2Clipboard =>
      'Copiar JSON v2 para a área de transferência';

  @override
  String get paoSnackbarPasteImageUseTabs =>
      'Colar imagem: abra o separador 0–9, 00–99 ou 000–999 e toque numa linha.';

  @override
  String get paoSnackbarTapRowFirst =>
      'Toque primeiro numa linha para escolher o código.';

  @override
  String get paoSnackbarCodeNotInTab =>
      'Código não encontrado neste separador.';

  @override
  String get paoSnackbarClipboardNoImage => 'Área de transferência: sem imagem';

  @override
  String get paoSnackbarCouldNotSaveImage =>
      'Não foi possível guardar a imagem';

  @override
  String get paoSnackbarCouldNotCopyImage => 'Não foi possível copiar a imagem';

  @override
  String paoSnackbarCodeImageUpdated(String code) {
    return 'Imagem do código $code atualizada';
  }

  @override
  String get paoSnackbarDropImageUseTabs =>
      'Largue a imagem no separador 0–9, 00–99 ou 000–999 (depois de tocar numa linha).';

  @override
  String paoEditDialogTitle(String code) {
    return 'PAO $code';
  }

  @override
  String get paoEditDeletePegButton => 'Apagar clavija';

  @override
  String get paoEditDeletePegConfirmTitle => 'Apagar esta clavija?';

  @override
  String get paoEditDeletePegConfirmBody =>
      'Isto remove texto e imagens deste código e apaga os ficheiros na pasta de assets do realm.';

  @override
  String get paoEditDeletePegSuccess => 'Clavija limpa';

  @override
  String get pokerMemoryTitle => 'Póquer · mapa numérico';

  @override
  String get pokerMemoryDrawerSubtitle =>
      'Número ↔ carta · 13 números por naipe · prática rápida';

  @override
  String get frameRecallQuizDrawerSubtitle =>
      'Quiz de 4 recortes · mesmo parcour';

  @override
  String get frameRecallQuizTitle => 'Recall de frame (protótipo)';

  @override
  String get frameRecallQuizIntro =>
      'Cada locus precisa de um bloco imagem com papel «Recall crop» (detalhe do hero). O hero não é mostrado aqui — só a pista [place] e quatro recortes. Escolhe o recorte que corresponde ao locus descrito.';

  @override
  String get frameRecallSelectParcour => 'Parcour';

  @override
  String frameRecallFramesWithCrop(int count) {
    return '$count frames com recorte recall';
  }

  @override
  String get frameRecallNeedFour =>
      'São precisos pelo menos 4 loci neste parcour com imagem «Recall crop». Edita cada locus e adiciona uma imagem com esse papel.';

  @override
  String get frameRecallNoParcours =>
      'Nenhum parcour sob o hub. Cria parcours primeiro.';

  @override
  String get frameRecallQuestion => 'Place / pista';

  @override
  String get frameRecallLocusLabel => 'Locus';

  @override
  String get frameRecallPickCrop => 'Qual recorte corresponde?';

  @override
  String get frameRecallCorrect => 'Correto.';

  @override
  String get frameRecallWrong => 'Errado — a margem verde é o recorte certo.';

  @override
  String get frameRecallNext => 'Próxima pergunta';

  @override
  String frameRecallMissingFile(String name) {
    return 'Ficheiro em falta: $name';
  }

  @override
  String get pokerMemoryTabMap => 'Mapa';

  @override
  String get pokerMemoryTabRanges => 'Intervalos';

  @override
  String get pokerMemoryTabDrill => 'Prática rápida';

  @override
  String get pokerMemoryMapIntro =>
      'Cada número corresponde a uma carta (A, 2–10, J, Q, K no bloco do naipe). Edita os intervalos no separador Intervalos.';

  @override
  String get pokerMemoryMapEmpty =>
      'Sem mapeamentos. Verifica os intervalos (cada naipe: exatamente 13 números, sem sobreposição).';

  @override
  String get pokerMemoryRangesIntro =>
      'Atribui um bloco contínuo de 13 números por naipe. Padrão: espadas 01–13, copas 41–53, ouros 61–73, paus 81–93.';

  @override
  String get pokerMemoryRangeFrom => 'De';

  @override
  String get pokerMemoryRangeTo => 'Até';

  @override
  String get pokerMemoryRangesSave => 'Guardar intervalos';

  @override
  String get pokerMemoryRangesSaved => 'Intervalos guardados';

  @override
  String get pokerMemoryRangesInvalidNumber =>
      'Introduz inteiros válidos em de / até.';

  @override
  String get pokerMemoryRangesHint =>
      'As ordens dos valores são A, 2, 3, …, 10, J, Q, K. Podem existir lacunas entre naipes.';

  @override
  String get pokerMemorySuitSpades => 'Espadas';

  @override
  String get pokerMemorySuitHearts => 'Copas';

  @override
  String get pokerMemorySuitDiamonds => 'Ouros';

  @override
  String get pokerMemorySuitClubs => 'Paus';

  @override
  String get pokerMemoryDrillInstruction =>
      'Recorda mentalmente o outro lado; depois revela e marca acerto ou falha.';

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
  String get pokerMemoryShowAnswer => 'Mostrar resposta';

  @override
  String get pokerMemoryAnswerHeading => 'Resposta';

  @override
  String get pokerMemoryAnswerNumber => 'Número';

  @override
  String get pokerMemoryAnswerCard => 'Carta';

  @override
  String get pokerMemoryPass => 'Acerto';

  @override
  String get pokerMemoryFail => 'Falha';

  @override
  String get pokerMemoryNext => 'Seguinte';

  @override
  String get pokerMemoryDrillEmpty =>
      'Nada para praticar. Corrige os intervalos.';

  @override
  String get matchCardsTitle => 'Cartas (parear)';

  @override
  String get matchCardsSubtitle =>
      'Imagem ↔ legenda · sessão aleatória (só LB)';

  @override
  String get matchCardsOrmHint =>
      'Cada par: lema (escrita nativa), transliteração opcional, significado (gloss) opcional e imagem. route_key é para um futuro «por percurso». As sessões escolhem cartas pelo passo Fibonacci (intervalo mais curto primeiro) e depois por mais falhas acumuladas.';

  @override
  String get matchCardsEmpty =>
      'Ainda não há pares. Adicione uma imagem e uma legenda.';

  @override
  String get matchCardsAddPair => 'Adicionar par';

  @override
  String get matchCardsPractice => 'Praticar';

  @override
  String get matchCardsDeleteTooltip => 'Remover par';

  @override
  String get matchCardsAddDialogTitle => 'Novo par';

  @override
  String get matchCardsLemmaLabel => 'Lema / palavra (escrita nativa)';

  @override
  String get matchCardsLemmaHint => 'ex. кошка';

  @override
  String get matchCardsLemmaRequired => 'Escreva primeiro o lema.';

  @override
  String get matchCardsTransliterationLabel => 'Transliteração (opcional)';

  @override
  String get matchCardsTransliterationHint => 'ex. koshka';

  @override
  String get matchCardsGlossLabel => 'Significado (opcional)';

  @override
  String get matchCardsGlossHint => 'ex. gato · cat';

  @override
  String get matchCardsPickImage => 'Escolher imagem';

  @override
  String get matchCardsCancel => 'Cancelar';

  @override
  String get matchCardsSessionTitle => 'Sessão de pares';

  @override
  String get matchCardsNeedTwoPairs =>
      'Adicione pelo menos dois pares em Cartas para jogar.';

  @override
  String get matchCardsNoMatch => 'Não combinam — tente de novo.';

  @override
  String get matchCardsPlayAgain => 'De novo';

  @override
  String get matchCardsSessionMenuTooltip => 'Sessão';

  @override
  String get matchCardsSessionNewRound => 'Nova ronda';

  @override
  String get matchCardsSessionChangeDeck => 'Mudar baralho…';

  @override
  String get matchCardsSessionStats => 'Cartas mais fracas…';

  @override
  String get matchCardsSessionStatsTitle => 'Estatísticas do baralho';

  @override
  String get matchCardsSessionStatsSubtitle =>
      'As rondas priorizam o passo Fibonacci mais baixo (precisa de prática) e depois mais falhas acumuladas. Cada par incorreto incrementa falhas nas duas cartas.';

  @override
  String get matchCardsSessionStatsEmpty =>
      'Ainda não há dados — jogue algumas rondas para ver contagens.';

  @override
  String matchCardsSessionStatsFailPass(int fails, int passes) {
    return '$fails falhas · $passes acertos';
  }

  @override
  String matchCardsSessionStatsFib(int n) {
    return 'Passo $n';
  }

  @override
  String matchCardsDeckOverviewKpis(
    int pairCount,
    int dueCount,
    String matchRate,
  ) {
    return '$pairCount pares · $dueCount a rever · taxa de acertos $matchRate';
  }

  @override
  String get matchCardsDeckOverviewFibBars =>
      'Pares por passo Fibonacci (altura da barra)';

  @override
  String get matchCardsSessionPickDeckTitle => 'Escolher baralho';

  @override
  String matchCardsAttempts(int count) {
    return 'Tentativas: $count';
  }

  @override
  String get matchCardsComplete => 'Concluído';

  @override
  String get matchCardsPairsRemaining => 'pares restantes';

  @override
  String get matchCardsPasteDropHint =>
      'Colar imagem: Ctrl+V (⌘V no Mac) fora do campo de texto. Ou largue um ficheiro aqui. As legendas aceitam qualquer escrita (chinês, japonês, russo…).';

  @override
  String get matchCardsLemmaUnicodeHelper => 'Qualquer escrita — UTF-8.';

  @override
  String get matchCardsImageReady =>
      'Imagem pronta — escreva a legenda e guarde.';

  @override
  String get matchCardsPasteImageInDialog =>
      'Colar imagem da área de transferência';

  @override
  String get matchCardsSavePair => 'Guardar par';

  @override
  String get matchCardsImageRequired =>
      'Escolha, cole ou largue uma imagem primeiro.';

  @override
  String get matchCardsClipboardNoImage =>
      'A área de transferência não tem imagem.';

  @override
  String get matchCardsDeckLabel => 'Baralho';

  @override
  String get matchCardsDeckMenuTooltip => 'Baralhos · exportar · importar';

  @override
  String get matchCardsNewDeckMenu => 'Novo baralho…';

  @override
  String get matchCardsRenameDeckMenu => 'Renomear baralho…';

  @override
  String get matchCardsDeleteDeckMenu => 'Eliminar baralho…';

  @override
  String get matchCardsExportMenu => 'Exportar baralho (.zip)…';

  @override
  String get matchCardsImportMenu => 'Importar baralho (.zip)…';

  @override
  String get matchCardsNewDeckTitle => 'Novo baralho';

  @override
  String get matchCardsRenameDeckTitle => 'Renomear baralho';

  @override
  String get matchCardsDeleteDeckTitle => 'Eliminar baralho?';

  @override
  String get matchCardsDeleteDeckBody =>
      'Os pares deste baralho passam para outro.';

  @override
  String get matchCardsDeleteDeckConfirm => 'Eliminar';

  @override
  String get matchCardsDeckNameLabel => 'Nome';

  @override
  String get matchCardsExportTitle => 'Guardar exportação';

  @override
  String get matchCardsExportDone => 'Exportação guardada.';

  @override
  String matchCardsExportError(String error) {
    return 'Falha na exportação: $error';
  }

  @override
  String get matchCardsImportTitle => 'Novo baralho para importar';

  @override
  String get matchCardsImportDefaultDeckName => 'Importado';

  @override
  String get matchCardsImportNewDeckNameLabel => 'Nome do baralho';

  @override
  String get matchCardsImportNewDeckNameHelper =>
      'Os pares do ficheiro são adicionados a este baralho novo.';

  @override
  String get matchCardsImportConfirm => 'Importar';

  @override
  String matchCardsImportDone(int count) {
    return 'Importados $count par(es).';
  }

  @override
  String matchCardsImportError(String error) {
    return 'Falha na importação: $error';
  }

  @override
  String get matchCardsSearchHint => 'Pesquisar lema, transliteração, gloss…';

  @override
  String get matchCardsDuplicatesOnly => 'Só duplicados';

  @override
  String matchCardsDuplicateSummary(int groups) {
    return '$groups lema(s) duplicado(s) neste baralho';
  }

  @override
  String get matchCardsSearchNoResults =>
      'Nenhuma carta corresponde à pesquisa ou filtro.';

  @override
  String get matchCardsDuplicateLemmaTooltip =>
      'Mesmo lema que outra carta neste baralho';

  @override
  String get matchCardsDuplicateSaveTitle => 'Lema duplicado';

  @override
  String get matchCardsDuplicateSaveBody =>
      'Já existe um par com este lema no baralho.';

  @override
  String get matchCardsContinueAnyway => 'Guardar mesmo assim';

  @override
  String get goGameTitle => 'Go 9×9';

  @override
  String get goGameSubtitle =>
      'Capturas, sem suicídio, superko posicional. Dois passes seguidos terminam. Komi para brancas.';

  @override
  String get goGameModePvp => 'Dois jogadores';

  @override
  String get goGameModeBot => 'vs Bot (tu jogas pretas)';

  @override
  String get goGameNew => 'Novo jogo';

  @override
  String get goGamePass => 'Passar';

  @override
  String get goGameBlackTurn => 'Jogam pretas';

  @override
  String get goGameWhiteTurn => 'Jogam brancas';

  @override
  String get goGameBotThinking => 'Bot a pensar…';

  @override
  String get goGameIllegal => 'Jogada ilegal';

  @override
  String get goGameOver => 'Fim de jogo';

  @override
  String goGameScoreSummary(
    String blackPt,
    String whiteBoardPt,
    String komi,
    String whiteTotal,
    String verdict,
  ) {
    return 'Pretas $blackPt pt — Brancas $whiteBoardPt no tabuleiro + $komi komi = $whiteTotal pt. $verdict';
  }

  @override
  String get goGameVerdictDraw => 'Empate.';

  @override
  String goGameVerdictBlackWins(String margin) {
    return 'Pretas ganham por $margin pt.';
  }

  @override
  String goGameVerdictWhiteWins(String margin) {
    return 'Brancas ganham por $margin pt.';
  }

  @override
  String goGameStoneTotals(int blackStones, int whiteStones) {
    return 'Pedras no tabuleiro: pretas $blackStones · brancas $whiteStones';
  }

  @override
  String get goStudyTabFree => 'Jogo livre';

  @override
  String get goStudyTabProblems => 'Problemas';

  @override
  String get goStudyLibraryTooltip => 'Biblioteca de problemas e progresso';

  @override
  String get goStudyLibraryTitle => 'Problemas de Go';

  @override
  String goStudyLibraryLine(int solved, int mastered) {
    return '$solved resolvidos · $mastered estudados (3+ acertos)';
  }

  @override
  String get goStudyMasteredLabel => 'Estudado';

  @override
  String get goStudySolvedLabel => 'Resolvido uma vez';

  @override
  String goStudyAttemptsLabel(int n) {
    return '$n tentativas';
  }

  @override
  String get goStudyProblemWrong => 'Não é a jogada certa — tenta de novo.';

  @override
  String get goStudyProblemCorrect => 'Correto!';

  @override
  String get goStudyHint => 'Dica';

  @override
  String get goStudyShowLegal => 'Jogadas legais';

  @override
  String goStudyProblemIndex(int current, int total) {
    return 'Problema $current / $total';
  }

  @override
  String get goStudyNextProblem => 'Seguinte';

  @override
  String get goStudyPrevProblem => 'Anterior';

  @override
  String get goStudyResetProblem => 'Repor posição';

  @override
  String get goStudyPassDisabled => 'Passar está desligado neste modo.';

  @override
  String get goStudyBotDisabled => 'O bot fica desligado nos problemas.';

  @override
  String get goProblemCapTitle => 'Captura (atari)';

  @override
  String get goProblemCapHint => 'Tira a última liberdade da pedra branca.';

  @override
  String get goProblemConnectTitle => 'Ligar (lado)';

  @override
  String get goProblemConnectHint => 'Joga entre as duas pretas.';

  @override
  String get goProblemBridgeTitle => 'Ligar (cima/baixo)';

  @override
  String get goProblemBridgeHint => 'Une as duas pretas na mesma coluna.';

  @override
  String get metricsRecallTitle => 'Métricas de recall';

  @override
  String get metricsRecallSubtitle => 'Exportar CSV';

  @override
  String get realmsTitle => 'Reinos';

  @override
  String get realmsSubtitle => 'Núcleo · Ativo · Explorar';

  @override
  String get navigationIntentTitle => 'Navegação de estudo';

  @override
  String get navigationIntentTooltip =>
      'Toque para alternar modos. Com objeto focado, a linha 2 do bridge é a chave da moldura Hero para place / hint / história.';

  @override
  String get memoryAthleteSwitchTitle =>
      'Aprovação no parcour: 100% (atleta) vs 80% (padrão)';

  @override
  String get memoryAthleteSwitchSubtitleOn =>
      'Ligado — exige aprovação total (100% da pontuação da sessão).';

  @override
  String get memoryAthleteSwitchSubtitleOff =>
      'Desligado — aprovar com pelo menos 80% da pontuação (padrão).';

  @override
  String get studyNavigationTitle => 'Navegação de estudo';

  @override
  String get studyNavigationTooltip =>
      'Toque para mudar o modo. O subtítulo indica modo e chave da moldura Hero.';

  @override
  String studyNavigationDetailModeOnly(String mode) {
    return 'Modo: $mode';
  }

  @override
  String studyNavigationDetailWithFrame(String mode, String frame) {
    return 'Modo: $mode\nMoldura (Hero locus): $frame';
  }

  @override
  String get menuTooltip => 'Menu';

  @override
  String get backTooltip => 'Subir';

  @override
  String get searchTooltip =>
      'Pesquisar objetos (FTS5) · Núcleo · Ativo · Explorar';

  @override
  String get refreshTooltip => 'Regenerar snapshot / lista';

  @override
  String get emptyLevelMessage =>
      'Sem entradas neste nível.\nVolte para continuar.';

  @override
  String get tooltipDoubleTapObject =>
      'Duplo toque: leitor de conteúdo (node card)';

  @override
  String get tooltipDoubleTapEnter => 'Duplo toque para entrar no nível';

  @override
  String get tooltipRoleObject =>
      'Papel (só LB). Duplo toque: leitor de conteúdo.';

  @override
  String get tooltipRoleEnter =>
      'Papel (só LB; GK não lê). Duplo toque na linha para entrar.';

  @override
  String lastReviewPrefix(String when) {
    return '·  Última revisão: $when';
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
  String get languageTitle => 'Idioma da interface';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSystem => 'Idioma do dispositivo';

  @override
  String get languageChanged => 'Idioma atualizado';

  @override
  String get edit => 'Editar';

  @override
  String get moveObjectTooltip =>
      'Mover para outro parcour / slot (substitui destino)';

  @override
  String get moveParcourTooltip =>
      'Mover para outro parcour (substitui destino)';

  @override
  String get studyTooltip => 'Estudo';

  @override
  String get reviewAgain => 'De novo';

  @override
  String get reviewHard => 'Difícil';

  @override
  String get reviewGood => 'Bom';

  @override
  String get reviewEasy => 'Fácil';

  @override
  String statsRecallLine(int due, int n, int total) {
    return 'Recall (entradas) · a vencer $due · novas $n · total $total';
  }

  @override
  String parcourRowRecallLine(int due, int n, int total) {
    return 'Recall · a vencer $due · novas $n · total $total';
  }

  @override
  String get realmNA => 'Realm: N/D';

  @override
  String realmPercent(int percent, int good, int active) {
    return 'Realm: $percent% (good $good / ativos $active)';
  }

  @override
  String get dialogMoveParcourTitle => 'Mover parcour';

  @override
  String get dialogMoveObjectTitle => 'Mover objeto';

  @override
  String originLabel(String key) {
    return 'Origem: $key';
  }

  @override
  String get moveParcourHint =>
      'Escolha o parcour que substituirá o destino (mesmo número de filhos objeto).';

  @override
  String get moveParcourBodyWarning =>
      'O subárvore de destino é removido e substituído pelo de origem. O slot de origem volta ao esqueleto vazio (L1…L20).';

  @override
  String get destinationParcourLabel => 'Parcour de destino';

  @override
  String get moveObjectBodyWarning =>
      'Se o slot de destino já tiver conteúdo, é substituído. A lacuna no parcour de origem é preenchida com o esqueleto.';

  @override
  String get slotLabel => 'Slot (1–20)';

  @override
  String get moveObjectHint =>
      'Escolha parcour e slot (seq). O objeto vai para Parent_O## desse seq.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get move => 'Mover';

  @override
  String get snackbarNoDestParcour => 'Não há outro parcour como destino.';

  @override
  String snackbarParcourMoved(String from, String to) {
    return 'Parcour movido: $from → $to';
  }

  @override
  String get snackbarNoParcoursUnderHub => 'Sem parcours sob PARCOUR_MAIN.';

  @override
  String snackbarObjectMoved(String obj, String dest) {
    return 'Objeto movido: $obj → $dest';
  }

  @override
  String snackbarNuclearError(String error) {
    return 'Erro ao apagar: $error';
  }

  @override
  String get breadcrumbRoot => 'R1';

  @override
  String get breadcrumbParcours => 'Parcours (R1)';

  @override
  String intentFrameSuffix(String focus) {
    return ' · moldura $focus';
  }

  @override
  String intentDrawerWithFrame(String mode, String frame) {
    return '$mode · moldura $frame';
  }

  @override
  String intentSnackbar(String mode, String frameSuffix) {
    return 'Modo → $mode$frameSuffix (HUD visualizador 3D)';
  }

  @override
  String keySeqLine(String key, String seq) {
    return 'chave=$key  ·  seq=$seq';
  }

  @override
  String parcourReviewTooltip(String rating) {
    return 'Último Parcour Review: $rating';
  }

  @override
  String get parcourReviewNoData => 'sem dado';

  @override
  String get timeReviewNever => 'nunca';

  @override
  String get timeReviewUpcoming => 'futuro';

  @override
  String get timeReviewToday => 'hoje';

  @override
  String get timeReviewYesterday => 'ontem';

  @override
  String timeReviewDaysAgo(int count) {
    return 'há $count dias';
  }

  @override
  String timeReviewWeeksAgo(int count) {
    return 'há $count semanas';
  }

  @override
  String timeReviewMonthsAgo(int count) {
    return 'há $count meses';
  }

  @override
  String timeReviewYearsAgo(int count) {
    return 'há $count anos';
  }

  @override
  String get dueTagNew => 'novo';

  @override
  String get dueTagDue => 'a vencer';

  @override
  String dueTagInHours(int h) {
    return 'em ${h}h';
  }

  @override
  String dueTagInDays(int d) {
    return 'em ${d}d';
  }

  @override
  String get fibScheduleEmpty => 'Fib · sem objetos neste nível';

  @override
  String fibScheduleLine(String prev, String next) {
    return 'Fib · última: $prev · próximo: $next';
  }

  @override
  String get fibOverdue => 'em atraso';

  @override
  String fibRelPastMinutes(int m) {
    return 'há ${m}m';
  }

  @override
  String fibRelPastHours(int h) {
    return 'há ${h}h';
  }

  @override
  String fibRelPastDays(int d) {
    return 'há ${d}d';
  }

  @override
  String fibRelFutureMinutes(int m) {
    return 'em ${m}m';
  }

  @override
  String fibRelFutureHours(int h) {
    return 'em ${h}h';
  }

  @override
  String fibRelFutureDays(int d) {
    return 'em ${d}d';
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
      other: 'em $count dias',
      one: 'em 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get parcourFibDueOverdue => 'due em atraso';

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
  String get locusEditorAddBlockTooltip => 'Adicionar bloco';

  @override
  String get locusEditorBlockParagraph => 'Parágrafo';

  @override
  String get locusEditorBlockLink => 'Link';

  @override
  String get locusEditorBlockImage => 'Imagem';

  @override
  String get locusEditorBlockCard => 'Cartão';

  @override
  String get locusEditorCardWordLabel => 'Palavra / lema';

  @override
  String get locusEditorCardImageLabel => 'Ilustração (ficheiro em assets)';

  @override
  String get locusEditorCardPhoneticLabel =>
      'Fonética / notas (ficheiro, ex. ipa.txt)';

  @override
  String get locusEditorCardAudioLabel =>
      'Áudio de pronúncia (ogg / mp3 / wav)';

  @override
  String get locusEditorCardRelatedLabel => 'Chaves de entradas relacionadas';

  @override
  String get locusEditorCardRelatedHint =>
      'Separadas por vírgula ou espaço (devem existir neste realm)';

  @override
  String get locusEditorEmptyBlocksHint =>
      'Ainda não há blocos. Adicione parágrafo, link, imagem ou cartão de vocabulário — ou cole/largue uma imagem.';

  @override
  String locusEditorUnknownRelatedKey(String key) {
    return 'Chave relacionada inexistente neste realm: $key';
  }

  @override
  String get locusEditorSpatialTurnTooltip =>
      'Curva espacial (caminho para a próxima moldura no GateKeeper)';

  @override
  String get locusEditorSpatialStraight => 'Reto';

  @override
  String get locusEditorSpatialLeft => 'Esquerda';

  @override
  String get locusEditorSpatialRight => 'Direita';

  @override
  String get locusEditorMenuTooltip => 'Definições do locus, papel, ajuda';

  @override
  String get locusEditorSave => 'Guardar';

  @override
  String get locusEditorSaved => 'Guardado';

  @override
  String locusEditorSubtitleLine(String role, String turn) {
    return '$role · $turn';
  }

  @override
  String get locusEditorHelpMenuLabel => 'Ajuda do editor de locus';

  @override
  String get locusEditorHelpMenuSubtitle =>
      'O que este ecrã faz e como sincroniza com o GateKeeper';

  @override
  String get locusEditorHelpDialogTitle => 'Como usar o editor de locus';

  @override
  String get locusEditorDeleteMenuLabel => 'Eliminar este locus';

  @override
  String get placeRecallDrawerTitle => 'Place recall';

  @override
  String get placeRecallDrawerSubtitle =>
      'Liga o gate de recortes no visualizador 3D (ou use o modo de estudo place_recall). Precisa de assets recall_crop; distratores vêm de irmãos do parcour quando possível.';

  @override
  String get locusEditorDeleteMenuSubtitle =>
      'Elimina esta entrada e descendentes da base de dados e ficheiros do realm; não apaga o ficheiro inteiro da DB.';

  @override
  String get locusEditorDeleteConfirmTitle => 'Eliminar locus permanentemente';

  @override
  String locusEditorDeleteConfirmDescription(String realmPath) {
    return 'Remove esta entrada e todos os descendentes da base de dados do realm ($realmPath), apaga linhas nas tabelas review/parcour, remove ficheiros de assets/snapshot/viewer/manifest para essas chaves e reconstrói snapshots.';
  }

  @override
  String locusEditorDeleteConfirmDeletingLabel(String key) {
    return 'A eliminar: $key';
  }

  @override
  String get locusEditorDeleteConfirmTypeInstruction =>
      'Isto vai eliminar o locus indicado acima. Para confirmar, escreva na caixa a frase abaixo exatamente — não é a chave da base de dados. Respeite espaços e maiúsculas:';

  @override
  String get locusEditorDeleteConfirmPhraseExact => 'Delete Node';

  @override
  String get locusEditorDeleteConfirmFieldHint => 'Delete Node';

  @override
  String get locusEditorDeleteConfirmButton => 'Eliminar';

  @override
  String get locusEditorHelpDialogBody =>
      'Neste ecrã edita uma entrada do realm: blocos de texto, links, imagens e cartões de vocabulário.\n\nPapel cognitivo — Realm (contentor), Parcour (corredor de molduras) ou Objeto (o que lê no visualizador do GateKeeper). Os filhos sob um parcour são molduras ordenadas no percurso 3D.\n\nBlocos — Parágrafos podem ser texto simples ou tipos de estudo: Lugar, Dica, História ridícula. As imagens escolhem papel: Conteúdo (só no visualizador), Collage (painéis na parede do GateKeeper entre molduras) ou Hero (a imagem na moldura 3D). Hero rápido: foco num bloco imagem e Ctrl/Cmd+H.\n\nCartões — Palavra ou lema, ilustração e áudio em assets desta chave, ficheiro opcional de fonética e chaves relacionadas que já existam no realm.\n\nCurva espacial — Para entradas filhas diretas de um parcour, defina como o corredor segue para a próxima moldura (reto, esquerda, direita).\n\nPlace recall — Em objetos, ative place recall para o exercício no GateKeeper. Adicione imagem com papel Recall crop; o exercício precisa desta moldura e de três outros objetos no realm com recall_crop válidos.\n\nColar e ficheiros — Cole texto ou imagens com Ctrl+V / Cmd+V com o foco fora dos campos de texto. No ambiente de trabalho, largue .png / .jpg / .webp na zona de destino.\n\nGuardar — Escreve a base de dados, copia assets e atualiza visualizador e snapshots para o GateKeeper recarregar.';

  @override
  String get sectionHelp => 'AJUDA';

  @override
  String get helpGuideTitle => 'Como funciona Alexandria';

  @override
  String get helpGuideClose => 'Fechar';

  @override
  String get helpGuideGkHint => 'No GateKeeper, prima F1 para este guia.';

  @override
  String get helpGuideOverviewTitle => 'Visão geral';

  @override
  String get helpGuideOverviewBody =>
      'Alexandria liga duas aplicações à mesma pasta de dados. Library Build (LB) edita a árvore do realm, conteúdo dos loci, imagens e revisões. GateKeeper (GK) é o corredor 3D: caminha entre molduras e abre o viewer. Ambos leem a mesma base SQLite e assets; uma pasta bridge indica ao GK qual nível e moldura estão ativos.';

  @override
  String get helpGuideRolesTitle => 'Realms, parcours e objetos';

  @override
  String get helpGuideRolesBody =>
      'A árvore começa em ROOT, segue realms (ex.: R1), o hub de parcours (PARCOUR_MAIN), parcours numerados (P1…P20) e objetos sob cada parcour. Cada linha tem papel cognitivo: Realm (contentor), Parcour (sequência de molduras no corredor) ou Objeto (folha com conteúdo completo). No LB define papéis ao criar ou editar. No GK o parcour mostra muitas molduras ao longo do percurso; o objeto foca uma moldura.';

  @override
  String get helpGuideContentTitle => 'Hero, collage e corpo';

  @override
  String get helpGuideContentBody =>
      'No editor de locus, imagens podem ser só viewer, Collage (painéis na parede do GK) ou Hero (imagem da moldura 3D). Blocos de texto podem ter place, hint ou ridiculous story para estudo. Ao guardar, atualizam-se ficheiros em assets/<chave>/ e snapshots para o GK regenerar o corredor.';

  @override
  String get helpGuideCardsTitle => 'Cartões de vocabulário';

  @override
  String get helpGuideCardsBody =>
      'Adicione um bloco Cartão para entradas de idioma: palavra em destaque, ilustração em assets/<chave>/, fonética opcional (.txt), áudio opcional (ogg/mp3/wav) e related_to com outras chaves do realm. No GateKeeper, as relacionadas só mudam o foco (mesmo corredor); Voltar regressa ao foco anterior.';

  @override
  String get helpGuideLbTitle => 'Library Build — o que pode fazer';

  @override
  String get helpGuideLbBody =>
      'Navegue pela barra e gaveta: abra qualquer nível, edite um locus (duplo toque), pesquise objetos, atualize snapshots. A gaveta oferece PDF de nó, PDF de parcour, importação, ferramentas PAO, exportação de métricas recall, idioma, pastas de realm e intent de navegação (explore / review / seek / drift — opcionalmente ligado a um locus em foco). A lista mostra datas de recall, histórico, semáforo Parcour Review e linhas Fib quando aplicável.';

  @override
  String get helpGuideGkTitle => 'GateKeeper — realm 3D';

  @override
  String get helpGuideGkBody =>
      'Movimento WASD, vista com o rato (Esc liberta ou recaptura o cursor). Clique numa moldura define o foco do viewer; no viewer entra no filho ou volta ao pai. A linha superior mostra o intent vindo do LB. O traçado segue curvas espaciais definidas por moldura no LB (reto, esquerda, direita).';

  @override
  String get helpGuideMetricsTitle => 'Métricas e revisões';

  @override
  String get helpGuideMetricsBody =>
      'O LB guarda recall por entrada (próxima revisão, força, contagens) e avaliações Parcour Review. A página de métricas exporta CSV. Na lista, insígnias e tooltips resumem vencimentos e última Parcour Review sob um parcour.';

  @override
  String get helpGuideBridgeTitle => 'Bridge e sincronia';

  @override
  String get helpGuideBridgeBody =>
      'Ficheiros em data/…/bridge/ levam context_key, focus_key, navigation_intent.txt e sinais de refresh. Após editar no LB, use Atualizar para alinhar snapshots e manifestos; o GK reage quando esses ficheiros mudam.';

  @override
  String get usageBandAll => 'Todos';

  @override
  String get usageBandCore => 'Núcleo';

  @override
  String get usageBandActive => 'Ativo';

  @override
  String get usageBandSeek => 'Explorar';

  @override
  String get usageBandSubtitleCore => 'Núcleo de uso (maior engagement)';

  @override
  String get usageBandSubtitleActive => 'Uso recorrente';

  @override
  String get usageBandSubtitleSeek => 'Exploração / cauda longa';

  @override
  String get realmShelfPopupCore => 'Núcleo — prioridade';

  @override
  String get realmShelfPopupActive => 'Ativo — uso regular';

  @override
  String get realmShelfPopupSeek => 'Explorar — resto';

  @override
  String get realmAdminFabCreate => 'Criar realm novo';

  @override
  String get realmAdminTabFolders => 'Pastas';

  @override
  String get realmAdminTabShelves => 'Prateleiras';

  @override
  String get realmAdminTooltipEmptySubfolder =>
      'Pasta vazia (só organização, sem realm)';

  @override
  String get realmAdminTooltipRefresh => 'Atualizar lista';

  @override
  String get realmAdminTooltipOpenExplorer => 'Abrir esta pasta no explorador';

  @override
  String get realmAdminTooltipCreateSeed =>
      'Criar realm seed do realm ativo (data/realm_seed/)';

  @override
  String get realmAdminTooltipNuclear =>
      'Limpar bibliotecas de realm (irreversível) — PAO e Match cards são preservados';

  @override
  String get realmAdminCleanupMenuTooltip => 'Limpar só PAO ou Match cards';

  @override
  String get realmAdminCleanPaoTitle => 'Limpar dados PAO';

  @override
  String get realmAdminCleanPaoBody =>
      'Remove linhas PAO na base do realm ativo e JSON de utilizador em data/pao/ (mantêm-se ficheiros *.template). Não altera a árvore do realm nem Match cards.';

  @override
  String get realmAdminCleanPaoConfirm => 'Limpar PAO';

  @override
  String get realmAdminCleanPaoSnackbar => 'Dados PAO limpos.';

  @override
  String get realmAdminCleanMatchTitle => 'Limpar dados Match cards';

  @override
  String get realmAdminCleanMatchBody =>
      'Apaga baralhos, pares, estado de revisão e ficheiros em assets/lb_match_cards/ do realm ativo. Irreversível.';

  @override
  String get realmAdminCleanMatchConfirm => 'Limpar Match cards';

  @override
  String get realmAdminCleanMatchSnackbar => 'Dados Match cards limpos.';

  @override
  String get realmAdminMatchCardsTileTitle => 'Match cards';

  @override
  String get realmAdminMatchCardsTileSubtitle =>
      'Baralhos e pares imagem–texto do realm ativo. Abre a vista Match cards no início da biblioteca.';

  @override
  String get realmAdminTooltipOpenRealmFolder =>
      'Abrir pasta do realm no explorador';

  @override
  String get realmAdminTooltipMoveShelf => 'Alterar prateleira';

  @override
  String get realmAdminTooltipEnterSubfolders => 'Entrar em subpastas';

  @override
  String get realmAdminTooltipShelfMenu => 'Prateleira';

  @override
  String get realmAdminTooltipMoveRealm => 'Mover ou renomear o realm no disco';

  @override
  String get realmAdminMoveRealmMenu => 'Mover para caminho…';

  @override
  String get realmAdminMoveRealmTitle => 'Mover realm';

  @override
  String get realmAdminMoveRealmBody =>
      'Nova localização sob data/realms/. O destino não pode existir. A base de dados fecha um momento.';

  @override
  String get realmAdminMoveRealmTargetLabel =>
      'Novo caminho (ex. Lab/meu_curso)';

  @override
  String realmAdminMoveRealmOk(String path) {
    return 'Movido para $path';
  }

  @override
  String get realmAdminMoveRealmFailed =>
      'Não foi possível mover (pasta existente ou ficheiros em uso).';

  @override
  String get realmAdminMoveRealmButton => 'Mover';

  @override
  String get realmAdminShelvesIntro =>
      'Só um realm ativo de cada vez (GK lê data/active_realm.txt). Núcleo / Ativo / Explorar são prateleiras de prioridade (não são pastas físicas).';

  @override
  String realmAdminActiveLine(String id) {
    return 'Ativo: $id';
  }

  @override
  String get realmAdminTierHeaderCore => 'Mais importante / em uso';

  @override
  String get realmAdminTierHeaderActive => 'Realms de trabalho habitual';

  @override
  String get realmAdminTierHeaderSeek => 'Cauda longa e experimentação';

  @override
  String get realmAdminEmptyTier => 'Vazio';

  @override
  String get realmAdminFolderIntro =>
      'Lista o que existe em disco sob data/realms/ na raiz resolvida (não é inventado). Realm = pasta com alexandria.db. Mover muitas pastas: prefira com apps fechadas se a DB estiver em uso.';

  @override
  String get realmAdminRepoRootCaption =>
      'Raiz do repo (env ALEXANDRIA_ROOT, ou pesquisa a partir do .exe, ou C:\\\\Alexandria se tiver data/realms):';

  @override
  String get realmAdminRealmsFolderCaption =>
      'Pasta realms (deve coincidir com o explorador):';

  @override
  String get realmAdminFolderEmpty => 'Pasta vazia.';

  @override
  String get realmAdminLeafFolderWithoutDb =>
      'Pasta sem alexandria.db nem subpastas';

  @override
  String get realmAdminRootGroupLabel => 'Raiz (sem subpasta)';

  @override
  String get realmAdminDataRealmsChip => 'data/realms';

  @override
  String realmAdminShelfLabel(String tier) {
    return 'Prateleira: $tier';
  }

  @override
  String get objectSearchUsageCaption =>
      'Vistas por uso: Núcleo · Ativo · Explorar (mesmos loci; não muda a estrutura).';

  @override
  String realmAdminExplorerMissingFolder(String root, String path) {
    return 'Essa pasta não existe em disco.\nRaiz resolvida: $root\nCaminho tentado:\n$path';
  }

  @override
  String realmAdminExplorerError(String error, String path) {
    return 'Explorador: $error\n$path';
  }

  @override
  String realmAdminFolderMissing(String path) {
    return 'Pasta inexistente:\n$path';
  }

  @override
  String realmAdminOpenFailed(String error) {
    return 'Não foi possível abrir: $error';
  }

  @override
  String get realmAdminEmptyFolderDialogTitle => 'Pasta vazia';

  @override
  String realmAdminEmptyFolderBody(String path) {
    return 'Só organização (sem alexandria.db). Criada em:\n$path';
  }

  @override
  String get realmAdminEmptyFolderNameLabel => 'Nome da pasta';

  @override
  String get realmAdminEmptyFolderNameHint => 'ex.: Lab ou Clientes_2026';

  @override
  String get realmAdminEmptyFolderNameHelper => 'Um segmento; sem /';

  @override
  String get realmAdminSnackbarSingleSegment => 'Use um único nome sem /';

  @override
  String get realmAdminSnackbarSubfolderCreateFailed =>
      'Não foi possível criar (já existe realm com DB aí, ou nome inválido?).';

  @override
  String get realmAdminSnackbarFolderCreated => 'Pasta criada';

  @override
  String get realmDialogNewTitle => 'Novo realm';

  @override
  String get realmDialogFolderOptionalLabel => 'Pasta opcional';

  @override
  String get realmDialogFolderHint => 'ex.: Lab ou Clientes/2026';

  @override
  String get realmDialogFolderHelper =>
      'Sob data/realms/; vazio = raiz. O separador Pastas preenche a vista atual.';

  @override
  String get realmDialogIdLabel => 'Id do realm';

  @override
  String get realmDialogIdHint => 'ex.: meu_reino';

  @override
  String get realmDialogIdHelper => 'Um nome; sem /';

  @override
  String get realmDialogTemplateCopyTitle => 'Copiar de modelo';

  @override
  String get realmDialogTemplateCopySubtitle =>
      'Duplica DB, bridge, snapshot, assets… de outro realm.';

  @override
  String get realmDialogEmptyTitle => 'Vazio (mesma arquitetura)';

  @override
  String get realmDialogEmptySubtitle =>
      'Mesma árvore fixa (20 parcours + 400 objetos sob PARCOUR_MAIN), mas sem texto nos loci, sem recall/review e assets vazios.';

  @override
  String get realmDialogTemplateLabel => 'Modelo';

  @override
  String get realmDialogCreate => 'Criar';

  @override
  String get realmDialogIdInvalidChars =>
      'O id do realm não pode conter / nem \\.';

  @override
  String get realmSnackbarCreateEmptyFailed =>
      'Não foi possível criar vazio (caminho duplicado ou erro ao escrever?).';

  @override
  String get realmSnackbarDuplicateFailed =>
      'Não foi possível copiar (modelo em falta, caminho duplicado?).';

  @override
  String realmSnackbarActiveRealm(String id) {
    return 'Realm ativo: $id';
  }

  @override
  String get realmAdminNuclearTitle => 'Apagar todos os dados';

  @override
  String get realmAdminNuclearDialogIntro =>
      'Serão removidas todas as pastas sob data/realms/ (assets, bridge, snapshots, manifests, realm_shelf.json). A pasta data/pao/ do repositório não é apagada.\n\nOs dados PAO e Match cards do realm ativo são copiados para a nova base default e assets.\n\nFicará apenas uma base nova em:\ndata/realms/default/alexandria.db\n\nTambém será escrito o snapshot realm seed em:\ndata/realm_seed/alexandria.db\n\nRealm ativo: default.\n\nFeche o visualizador 3D se estiver aberto (bloqueio de ficheiros).\n\nPara confirmar, escreva exatamente:';

  @override
  String get realmAdminConfirmLabel => 'Confirmação';

  @override
  String get realmAdminPhraseMismatch => 'A frase não coincide exatamente.';

  @override
  String get realmAdminNuclearButton => 'Apagar tudo';

  @override
  String get realmAdminNuclearSuccessSnackbar =>
      'Bibliotecas de realm limpas; PAO e Match cards restaurados no default. default/alexandria.db + data/realm_seed/alexandria.db. Execute Library build ou reabra a app para regenerar snapshot/viewer.';

  @override
  String get realmSeedDialogTitle => 'Criar realm seed';

  @override
  String realmSeedDialogBody(String realm) {
    return 'O realm ativo ($realm) será sanitizado, Library build corre e a DB será copiada para:\ndata/realm_seed/alexandria.db\n\nFeche o GateKeeper se estiver aberto.';
  }

  @override
  String get realmSeedConfirm => 'Criar';

  @override
  String get realmSeedSavedSnackbar =>
      'Realm seed guardado: data/realm_seed/alexandria.db';

  @override
  String get realmSeedErrorPrefix => 'Realm seed:';

  @override
  String get objectSearchTitle => 'Pesquisar objetos (FTS5)';

  @override
  String get objectSearchHint => 'Título ou texto do locus…';

  @override
  String get objectSearchCardReaderTooltip => 'Leitor em cartão (toda a info)';

  @override
  String get objectSearchNoObjects => 'Sem objetos na base.';

  @override
  String get objectSearchNoMatches => 'Sem correspondências.';
}
