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
  String get paoEditorTitle => 'PAO (00–99)';

  @override
  String get paoEditorSubtitle => 'Sistema de 2 dígitos · import / export JSON';

  @override
  String get paoPracticeTitle => 'PAO · prática individual';

  @override
  String get paoPracticeSubtitle =>
      'Memória · mostrar respostas · acerto / falha';

  @override
  String get matchCardsTitle => 'Cartas (parear)';

  @override
  String get matchCardsSubtitle =>
      'Imagem ↔ legenda · sessão aleatória (só LB)';

  @override
  String get matchCardsOrmHint =>
      'Cada par: lema (escrita nativa), transliteração opcional, significado (gloss) opcional e imagem. route_key é para um futuro «por percurso»; a tabela FSRS existe mas sem agendador.';

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
  String goGameScoreLine(String blackPt, String whitePt, String komi) {
    return 'Pretas $blackPt — Brancas $whitePt (komi +$komi)';
  }

  @override
  String get metricsRecallTitle => 'Métricas de recall';

  @override
  String get metricsRecallSubtitle => 'Exportar CSV';

  @override
  String get realmsTitle => 'Reinos';

  @override
  String get realmsSubtitle => 'Núcleo · Ativo · Explorar';

  @override
  String get navigationIntentTitle => 'Intenção de navegação';

  @override
  String get navigationIntentTooltip =>
      'Modo explore / review / seek / drift. Com foco num objeto, guarda-se como «moldura»: place, hint e ridiculous story ligam ao Hero desse locus.';

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
    return 'Intent → $mode$frameSuffix (HUD GateKeeper)';
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
  String get locusEditorPasteHint =>
      'Colar: Ctrl+V. Papéis da imagem: Viewer / Collage / Hero. Hero rápido: imagem + Ctrl/Cmd+H. Mais: menu ☰';

  @override
  String get locusEditorSaved => 'Guardado';

  @override
  String locusEditorSubtitleLine(String role, String turn) {
    return '$role · $turn';
  }

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
  String get realmAdminTooltipNuclear => 'Apagar todos os dados (irreversível)';

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
      'Serão eliminados todos os realms, assets, bridge, snapshots, manifests, PAO em data/pao e realm_shelf.json.\n\nFicará apenas uma base nova em:\ndata/realms/default/alexandria.db\n\nTambém será escrito o snapshot realm seed em:\ndata/realm_seed/alexandria.db\n\nRealm ativo: default.\n\nFeche o GateKeeper se estiver aberto (bloqueio de ficheiros).\n\nPara confirmar, escreva exatamente:';

  @override
  String get realmAdminConfirmLabel => 'Confirmação';

  @override
  String get realmAdminPhraseMismatch => 'A frase não coincide exatamente.';

  @override
  String get realmAdminNuclearButton => 'Apagar tudo';

  @override
  String get realmAdminNuclearSuccessSnackbar =>
      'Dados apagados: default/alexandria.db + data/realm_seed/alexandria.db. Execute Library build ou reabra a app para regenerar snapshot/viewer.';

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
