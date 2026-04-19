/** UI language for Data transfer (cookie `dt_lang`: es | en). */

const COOKIE = 'dt_lang';

function parseCookie(header) {
  const o = {};
  if (!header || typeof header !== 'string') return o;
  header.split(';').forEach((part) => {
    const i = part.indexOf('=');
    if (i === -1) return;
    const k = part.slice(0, i).trim();
    try {
      o[k] = decodeURIComponent(part.slice(i + 1).trim());
    } catch {
      o[k] = part.slice(i + 1).trim();
    }
  });
  return o;
}

/** Resolve language: URL `lang=` overrides cookie; default `es`. */
function resolveLang(reqUrl, cookieHeader) {
  try {
    const u = new URL(reqUrl, 'http://localhost');
    const q = (u.searchParams.get('lang') || '').toLowerCase();
    if (q === 'en' || q === 'es') return q;
  } catch {
    /* ignore */
  }
  const c = parseCookie(cookieHeader || '');
  const v = (c[COOKIE] || '').toLowerCase();
  if (v === 'en' || v === 'es') return v;
  return 'es';
}

function normalizeLang(v) {
  const x = (v || '').toString().toLowerCase().trim();
  return x === 'en' ? 'en' : 'es';
}

function homeIntro(lang, maxUploadMb, maxSfsMb) {
  if (lang === 'en') {
    return `Light transport: <strong>out/</strong> (fast) and <strong>handoff/incoming/</strong> (debug packs). Limits: upload ≤${maxUploadMb} MiB, text /sfs ≤${maxSfsMb} MiB. Content is not interpreted.`;
  }
  return `Transporte ligero: <strong>out/</strong> (rápido) y <strong>handoff/incoming/</strong> (paquetes debug). Límites: subida ≤${maxUploadMb} MiB, texto /sfs ≤${maxSfsMb} MiB. Sin interpretar contenido.`;
}

function homeStrings(lang) {
  if (lang === 'en') {
    return {
      pageTitle: 'Data transfer',
      tabHome: 'Home',
      tabReader: 'Reader',
      tabSender: 'Sender',
      btnLatestOut: 'Latest in out/',
      btnOpenOut: 'Open OUT folder',
      btnOpenIncoming: 'Open incoming',
      btnCopyPaths: 'Copy paths (debug)',
      recentHeading: 'Recent in out/',
      loading: 'Loading…',
      empty: '(empty)',
      listError: 'Could not load list',
      urlCardLabel: 'LAN URL',
      copyUrl: 'Copy URL',
      sseLine: 'SSE:',
      sseConnected: 'connected',
      sseReconnecting: 'reconnecting…',
      sseUnavailable: 'unavailable',
      events: 'events:',
      openOutToast: 'Opening out/ in File Explorer…',
      openIncomingToast: 'Opening handoff/incoming/…',
      pathsCopiedToast: 'Paths copied to clipboard',
      errOpenFolder: 'Could not open folder',
      errServer: 'Could not reach server:',
      errList: 'Could not load list',
      newInBucket: 'New in',
      copyUrlOk: 'Copied:'
    };
  }
  return {
    pageTitle: 'Data transfer',
    tabHome: 'Inicio',
    tabReader: 'Reader',
    tabSender: 'Sender',
    btnLatestOut: 'Último en out/',
    btnOpenOut: 'Abrir carpeta OUT',
    btnOpenIncoming: 'Abrir incoming',
    btnCopyPaths: 'Copiar rutas (debug)',
    recentHeading: 'Recientes en out/',
    loading: 'Cargando…',
    empty: '(vacío)',
    listError: 'No se pudo cargar la lista',
    urlCardLabel: 'URL en red',
    copyUrl: 'Copiar URL',
    sseLine: 'SSE:',
    sseConnected: 'conectado',
    sseReconnecting: 'reconectando…',
    sseUnavailable: 'no disponible',
    events: 'eventos:',
    openOutToast: 'Abriendo carpeta out/ en el explorador…',
    openIncomingToast: 'Abriendo handoff/incoming/…',
    pathsCopiedToast: 'Rutas copiadas al portapapeles',
    errOpenFolder: 'Error al abrir la carpeta',
    errServer: 'No se pudo contactar al servidor:',
    errList: 'No se pudo cargar la lista',
    newInBucket: 'Nuevo en',
    copyUrlOk: 'Copiado:'
  };
}

function folderOpenForbiddenBody(lang, port) {
  if (lang === 'en') {
    return (
      'Only from this machine (127.0.0.1). Open http://127.0.0.1:' +
      port +
      ' on the PC running the server to open the folder.'
    );
  }
  return (
    'Solo desde este equipo (127.0.0.1). Abre http://127.0.0.1:' +
    port +
    ' en el PC que ejecuta el servidor para abrir la carpeta.'
  );
}

function latestStrings(lang) {
  if (lang === 'en') {
    return {
      title: 'Latest — Data transfer',
      noFiles: 'No files in',
      truncated: 'Truncated on server; download the full file.',
      copy: 'Copy',
      copied: 'Copied',
      home: 'Home'
    };
  }
  return {
    title: 'Último — Data transfer',
    noFiles: 'No hay archivos en',
    truncated: 'Vista truncada en servidor; descarga el archivo completo.',
    copy: 'Copiar',
    copied: 'Copiado',
    home: 'Inicio'
  };
}

function readerClientPack(lang) {
  if (lang === 'en') {
    return {
      menuTitle: 'Menu',
      menuAria: 'Menu',
      folderLabel: 'Folder:',
      optOutFast: 'out/ (fast)',
      optIncoming: 'handoff/incoming/ (packs)',
      home: 'Home',
      refreshList: 'Refresh list',
      refreshFiles: 'Refresh file list',
      downloadPrefix: 'Download ',
      morePrefix: '… and ',
      moreSuffix: ' more',
      top: 'Top'
    };
  }
  return {
    menuTitle: 'Menú',
    menuAria: 'Menú',
    folderLabel: 'Carpeta:',
    optOutFast: 'out/ (rápido)',
    optIncoming: 'handoff/incoming/ (packs)',
    home: 'Inicio',
    refreshList: 'Actualizar lista',
    refreshFiles: 'Refrescar archivos',
    downloadPrefix: 'Descargar ',
    morePrefix: '… y ',
    moreSuffix: ' más',
    top: 'Arriba'
  };
}

function senderClientPack(lang) {
  if (lang === 'en') {
    return {
      menuTitle: 'Menu',
      menuAria: 'Menu',
      home: 'Home',
      pickFile: 'Choose file',
      uploadOut: 'Upload → out/',
      uploadIncoming: 'Upload → incoming/ (debug pack)',
      hint: 'Streaming upload (does not load the whole file in RAM on the client). <code>incoming/</code> always uses a unique name. Optional <code>X-DT-Stable-Name: 1</code> on <code>out/</code> restores a fixed name (overwrites).',
      dropTitle: 'You can also click to choose a file',
      dropLine: 'Drop a file here → <strong>out/</strong> (or click to choose)',
      uploading: 'Uploading…',
      sendText: 'Send text',
      clear: 'Clear',
      noFile: 'No file',
      netErr: 'Network error'
    };
  }
  return {
    menuTitle: 'Menú',
    menuAria: 'Menú',
    home: 'Inicio',
    pickFile: 'Elegir archivo',
    uploadOut: 'Subir → out/',
    uploadIncoming: 'Subir → incoming/ (debug-pack)',
    hint: 'Subida por streaming (sin cargar todo en RAM en el cliente). <code>incoming/</code> siempre usa nombre único. Cabecera opcional <code>X-DT-Stable-Name: 1</code> en <code>out/</code> restaura nombre fijo (sobrescribe).',
    dropTitle: 'También puedes hacer clic para elegir archivo',
    dropLine: 'Suelta un archivo aquí → <strong>out/</strong> (o clic para elegir)',
    uploading: 'Subiendo…',
    sendText: 'Enviar texto',
    clear: 'Vaciar',
    noFile: 'Sin archivo',
    netErr: 'Error de red'
  };
}

module.exports = {
  COOKIE,
  parseCookie,
  resolveLang,
  normalizeLang,
  homeIntro,
  homeStrings,
  folderOpenForbiddenBody,
  latestStrings,
  readerClientPack,
  senderClientPack
};
