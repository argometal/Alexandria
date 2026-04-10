const http = require('http');
const fs = require('fs');
const path = require('path');

const {
  PORT,
  OUT_DIR,
  INCOMING_DIR,
  MAX_UPLOAD_BYTES,
  MAX_SFS_BYTES,
  MAX_READ_BYTES,
  bucketDir,
  CONFIG
} = require('./config');
const state = require('./state');
const { log } = require('./log');
const { sseBroadcast } = require('./sse');
const { getLocalIp, openDataTransferInBrowser } = require('./utils');
const { writeHowToFile } = require('./howto');
const { escapeHtml } = require('./html-utils');
const { renderReaderPanelHtml } = require('./panels/reader');
const { renderSenderPanelHtml } = require('./panels/sender');
const { streamBodyToFile } = require('./limited-stream');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function sanitizeFilename(raw) {
  const base = path.basename((raw || 'upload.bin').toString());
  return base.replace(/[<>:"/\\|?*\x00-\x1f]+/g, '_') || 'upload.bin';
}

function listFilesInDir(dir) {
  ensureDir(dir);
  return fs
    .readdirSync(dir)
    .map((name) => {
      try {
        const st = fs.statSync(path.join(dir, name));
        return st.isFile() ? { name, time: st.mtime.getTime() } : null;
      } catch (e) {
        return null;
      }
    })
    .filter(Boolean)
    .sort((a, b) => b.time - a.time)
    .map((f) => f.name);
}

function readTextLimited(filePath, maxBytes) {
  const st = fs.statSync(filePath);
  if (st.size <= maxBytes) {
    return { text: fs.readFileSync(filePath, 'utf8'), truncated: false };
  }
  const fd = fs.openSync(filePath, 'r');
  try {
    const buf = Buffer.allocUnsafe(maxBytes);
    const n = fs.readSync(fd, buf, 0, maxBytes, 0);
    const snippet = buf.slice(0, n).toString('utf8');
    return {
      text:
        snippet +
        `\n\n...[truncated: ${st.size} bytes, cap ${maxBytes} bytes — use /download]`,
      truncated: true
    };
  } finally {
    fs.closeSync(fd);
  }
}

function parseBucketFromUrl(reqUrl) {
  try {
    const u = new URL(reqUrl, 'http://localhost');
    const b = (u.searchParams.get('bucket') || 'out').toLowerCase();
    if (b === 'incoming') return 'incoming';
    return 'out';
  } catch (e) {
    return 'out';
  }
}

function postSfsHandler(req, res) {
  log('SFS', 'REQUEST');
  const tmp = path.join(OUT_DIR, '.partial-' + Date.now() + '-' + Math.random().toString(36).slice(2) + '.tmp');
  ensureDir(OUT_DIR);
  streamBodyToFile(req, tmp, MAX_SFS_BYTES)
    .then(({ bytes }) => {
      const savedName = Date.now() + '.txt';
      const finalPath = path.join(OUT_DIR, savedName);
      fs.renameSync(tmp, finalPath);
      log('SFS', 'OK', savedName + ' ' + bytes);

      const commitHdr = (req.headers['x-bridge-commit'] || '').toString().trim();
      state.lastCommitTime = new Date().toISOString();
      if (commitHdr) {
        if (commitHdr !== state.lastCommitHash) {
          state.lastCommitMessage = null;
        }
        state.lastCommitHash = commitHdr;
      }

      sseBroadcast({
        kind: 'sfs',
        bucket: 'out',
        file: savedName,
        commitHash: commitHdr || state.lastCommitHash,
        at: state.lastCommitTime
      });

      res.writeHead(200, {
        'Content-Type': 'text/plain; charset=utf-8',
        'X-Bridge-Filename': savedName
      });
      res.end('OK');
    })
    .catch((e) => {
      if (e && e.code === 'PAYLOAD_TOO_LARGE') {
        log('SFS', '413', String(MAX_SFS_BYTES));
        res.writeHead(413, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('PAYLOAD_TOO_LARGE max ' + MAX_SFS_BYTES + ' bytes');
        return;
      }
      log('SFS', 'ERROR', e.message);
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('ERROR');
    });
}

function postUploadHandler(req, res, targetDir, bucketLabel, nameMode) {
  const rawName = (req.headers['x-filename'] || 'upload.bin').toString();
  const safe = sanitizeFilename(rawName);
  const stable = (req.headers['x-dt-stable-name'] || '').toString().trim() === '1';
  const savedName =
    stable && nameMode !== 'incoming'
      ? safe
      : Date.now() + '_' + safe;
  const filePath = path.join(targetDir, savedName);

  ensureDir(targetDir);
  streamBodyToFile(req, filePath, MAX_UPLOAD_BYTES)
    .then(({ bytes }) => {
      log('UPLOAD', 'OK', bucketLabel + '/' + savedName + ' ' + bytes);
      state.lastCommitTime = new Date().toISOString();
      sseBroadcast({
        kind: 'sfs',
        bucket: bucketLabel,
        file: savedName,
        at: state.lastCommitTime
      });
      res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('UPLOADED: ' + savedName);
    })
    .catch((e) => {
      if (e && e.code === 'PAYLOAD_TOO_LARGE') {
        log('UPLOAD', '413', String(MAX_UPLOAD_BYTES));
        res.writeHead(413, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('PAYLOAD_TOO_LARGE max ' + MAX_UPLOAD_BYTES + ' bytes');
        return;
      }
      log('UPLOAD', 'ERR', e.message);
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('UPLOAD ERROR');
    });
}

function cleanDirFiles(dir, res) {
  try {
    ensureDir(dir);
    const files = fs.readdirSync(dir);
    let deleted = 0;
    for (const f of files) {
      if (f.startsWith('.')) continue;
      const p = path.join(dir, f);
      try {
        const st = fs.statSync(p);
        if (st.isFile()) {
          fs.unlinkSync(p);
          deleted++;
        }
      } catch (e) {
        /* skip */
      }
    }
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ ok: true, count: deleted }));
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ ok: false, error: e.message }));
  }
}

function requestHandler(req, res) {
  if (req.method === 'POST' && req.url === '/sfs') {
    postSfsHandler(req, res);
  } else if (req.method === 'GET' && req.url === '/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no'
    });
    res.write('\n');
    state.sseClients.add(res);
    req.on('close', () => {
      state.sseClients.delete(res);
    });
  } else if (req.method === 'GET' && req.url.split('?')[0] === '/files') {
    try {
      const bucket = parseBucketFromUrl(req.url);
      const dir = bucketDir(bucket);
      const files = listFilesInDir(dir);
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(files));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ error: e.message }));
    }
  } else if (req.method === 'GET' && req.url.startsWith('/download?name=')) {
    try {
      const host = req.headers.host || '127.0.0.1';
      const u = new URL(req.url, `http://${host}`);
      const name = decodeURIComponent(u.searchParams.get('name') || '').trim();
      const bucket = (u.searchParams.get('bucket') || 'out').toLowerCase() === 'incoming' ? 'incoming' : 'out';
      const dir = bucketDir(bucket);
      const file = path.join(dir, path.basename(name));
      if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('NOT FOUND');
        return;
      }
      res.writeHead(200, {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="' + path.basename(file) + '"'
      });
      fs.createReadStream(file).pipe(res);
    } catch (e) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('NOT FOUND');
    }
  } else if (req.method === 'GET' && req.url.startsWith('/read?name=')) {
    try {
      const host = req.headers.host || '127.0.0.1';
      const u = new URL(req.url, `http://${host}`);
      const name = decodeURIComponent(u.searchParams.get('name') || '').trim();
      const bucket = (u.searchParams.get('bucket') || 'out').toLowerCase() === 'incoming' ? 'incoming' : 'out';
      const dir = bucketDir(bucket);
      const file = path.join(dir, path.basename(name));
      if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('NOT FOUND');
        return;
      }
      const { text, truncated } = readTextLimited(file, MAX_READ_BYTES);
      res.writeHead(200, {
        'Content-Type': 'text/plain; charset=utf-8',
        ...(truncated ? { 'X-DT-Truncated': '1' } : {})
      });
      res.end(text);
    } catch (e) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('NOT FOUND');
    }
  } else if (req.method === 'GET' && req.url.split('?')[0] === '/reader') {
    const host = req.headers.host || '127.0.0.1';
    const urlObj = new URL(req.url, `http://${host}`);
    const openParam = urlObj.searchParams.get('open');
    const bucket = urlObj.searchParams.get('bucket') || '';
    let loc = '/?view=reader';
    if (bucket) loc += '&bucket=' + encodeURIComponent(bucket);
    if (openParam) {
      loc += '&open=' + encodeURIComponent(path.basename(openParam));
    }
    res.writeHead(302, { Location: loc });
    res.end();
  } else if (req.method === 'GET' && (req.url === '/' || req.url.startsWith('/?'))) {
    const ip = writeHowToFile();
    const baseUrl = `http://${ip}:${PORT}`;
    const readerHtml = renderReaderPanelHtml();
    const senderHtml = renderSenderPanelHtml();

    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Data transfer</title>
<style>
  :root {
    --bg:#0e0f12; --surface:#1a1c23; --border:#2a2d36; --text:#e8eaef; --muted:#8b919d; --accent:#ff6a00; --radius:10px;
  }
  body.dt-shell { margin:0; font-family:Segoe UI,system-ui,sans-serif; font-size:14px; color:var(--text); background:var(--bg);
    min-height:100vh; box-sizing:border-box; padding:14px 16px; }
  .dt-tabbar { display:flex; gap:8px; margin-bottom:14px; flex-wrap:wrap; align-items:center; border-bottom:1px solid var(--border); padding-bottom:12px; }
  .dt-tab { padding:8px 14px; font-size:14px; font-family:ui-monospace,monospace; cursor:pointer; border:1px solid var(--border); border-radius:var(--radius);
    background:var(--surface); color:var(--text); }
  .dt-tab:hover { background:#23262f; }
  .dt-tab.active { border-color:var(--accent); font-weight:bold; box-shadow:0 0 0 1px rgba(255,106,0,.2); }
  #dtToast { display:none; position:fixed; top:12px; right:12px; z-index:10000; max-width:min(360px,calc(100% - 24px));
    padding:10px 12px; background:#23262f; border:1px solid var(--border); border-radius:10px; font-size:14px; box-shadow:0 8px 24px rgba(0,0,0,.4); }
  #tab-home .dt-home-card { padding:14px; border:1px solid var(--border); border-radius:var(--radius); background:var(--surface); max-width:520px; }
  #tab-reader, #tab-sender { background:#f0f0f0; color:#111; border-radius:var(--radius); padding:12px; box-sizing:border-box; }
</style>
</head>
<body class="dt-shell">
<div id="dtToast"></div>
<div class="dt-tabbar">
  <button type="button" class="dt-tab active" id="dtBtnHome" onclick="dtShowTab('home')">Inicio</button>
  <button type="button" class="dt-tab" id="dtBtnReader" onclick="dtShowTab('reader')">Reader</button>
  <button type="button" class="dt-tab" id="dtBtnSender" onclick="dtShowTab('sender')">Sender</button>
</div>
<div id="tab-home">
  <h1 style="margin:0 0 8px 0;font-size:22px;">Data transfer</h1>
  <p style="margin:0 0 14px 0;font-size:13px;color:var(--muted);line-height:1.45;max-width:46em;">
    Transporte ligero: <strong>out/</strong> (rápido) y <strong>handoff/incoming/</strong> (paquetes debug). Límites: subida ≤${CONFIG.maxUploadMb} MiB, texto /sfs ≤${CONFIG.maxSfsMb} MiB. Sin interpretar contenido.
  </p>
  <div style="display:flex;flex-wrap:wrap;gap:10px;margin-bottom:14px;">
    <button type="button" class="dt-tab" style="border-radius:8px;" onclick="dtShowTab('reader')">Reader</button>
    <button type="button" class="dt-tab" style="border-radius:8px;" onclick="dtShowTab('sender')">Sender</button>
    <button type="button" class="dt-tab" style="border-radius:8px;" onclick="location.href='/latest'">Último en out/</button>
  </div>
  <div class="dt-home-card">
    <div style="font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;margin-bottom:6px;">URL en red</div>
    <div id="urlBox" style="font-family:monospace;font-size:15px;word-break:break-all;">${baseUrl}</div>
    <button type="button" onclick="dtCopyUrl()" style="margin-top:10px;padding:8px 14px;font-size:13px;cursor:pointer;border-radius:8px;border:1px solid var(--border);background:#2a2d36;color:var(--text);">Copiar URL</button>
  </div>
  <p style="font-size:12px;color:var(--muted);margin-top:14px;">SSE: <span id="dtSse">…</span> · eventos: <span id="dtSfsCount">0</span></p>
  <script>
  function dtCopyUrl() {
    var u = document.getElementById('urlBox').innerText;
    navigator.clipboard.writeText(u).then(function(){ alert('Copiado: ' + u); }).catch(function(){ alert(u); });
  }
  try {
    var es = new EventSource('/events');
    es.onopen = function(){ document.getElementById('dtSse').textContent = 'conectado'; };
    es.onmessage = function(ev){
      try {
        var d = JSON.parse(ev.data);
        if (d.kind === 'sfs') {
          var n = document.getElementById('dtSfsCount');
          n.textContent = parseInt(n.textContent, 10) + 1;
          var t = document.getElementById('dtToast');
          t.textContent = 'Nuevo en ' + (d.bucket || 'out') + '/: ' + (d.file || '');
          t.style.display = 'block';
          clearTimeout(dtToastTm);
          dtToastTm = setTimeout(function(){ t.style.display = 'none'; }, 4000);
        }
      } catch(e) {}
    };
    es.onerror = function(){ document.getElementById('dtSse').textContent = 'reconectando…'; };
  } catch(e) { document.getElementById('dtSse').textContent = 'no disponible'; }
  var dtToastTm = null;
  </script>
</div>
<div id="tab-reader" style="display:none;">${readerHtml}</div>
<div id="tab-sender" style="display:none;">${senderHtml}</div>
<script>
function dtShowTab(which) {
  var h = document.getElementById('tab-home');
  var r = document.getElementById('tab-reader');
  var s = document.getElementById('tab-sender');
  var bh = document.getElementById('dtBtnHome');
  var br = document.getElementById('dtBtnReader');
  var bs = document.getElementById('dtBtnSender');
  [h,r,s].forEach(function(el){ if(el) el.style.display = 'none'; });
  [bh,br,bs].forEach(function(b){ if(b) b.classList.remove('active'); });
  if (which === 'home') {
    h.style.display = 'block';
    bh.classList.add('active');
  } else if (which === 'reader' && r) {
    r.style.display = 'block';
    br.classList.add('active');
    try { if (typeof loadFiles === 'function') loadFiles(); } catch(e) {}
  } else if (which === 'sender' && s) {
    s.style.display = 'block';
    bs.classList.add('active');
  }
  try {
    var url = '/';
    if (which === 'reader') url = '/?view=reader';
    else if (which === 'sender') url = '/?view=sender';
    if (history.replaceState) history.replaceState(null, '', url);
  } catch(e) {}
}
(function(){
  try {
    var u = new URL(location.href);
    var v = u.searchParams.get('view');
    if (v === 'reader') dtShowTab('reader');
    else if (v === 'sender') dtShowTab('sender');
  } catch(e) {}
})();
</script>
</body>
</html>`);
  } else if (req.method === 'GET' && req.url.split('?')[0] === '/latest') {
    try {
      const u = new URL(req.url, 'http://localhost');
      const bucket = (u.searchParams.get('bucket') || 'out').toLowerCase() === 'incoming' ? 'incoming' : 'out';
      const dir = bucketDir(bucket);
      const names = listFilesInDir(dir);
      if (names.length === 0) {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('No hay archivos en ' + bucket + '/');
        return;
      }
      const latestFile = names[0];
      const filePath = path.join(dir, latestFile);
      const { text, truncated } = readTextLimited(filePath, MAX_READ_BYTES);
      const safe = escapeHtml(text);
      const safeName = escapeHtml(latestFile);
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(`<!DOCTYPE html>
<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Último — Data transfer</title>
<style>body{font-family:monospace;padding:12px;background:#f5f5f5;font-size:13px;} pre{white-space:pre-wrap;word-break:break-word;background:#fff;padding:12px;border-radius:6px;}
button{padding:10px 16px;margin:8px 0;cursor:pointer;border-radius:6px;border:1px solid #ccc;background:#222;color:#fff;}</style></head>
<body>
<h2>Último (${bucket}): ${safeName}</h2>
${truncated ? '<p style="color:#b71c1c;">Vista truncada en servidor; descarga el archivo completo.</p>' : ''}
<button type="button" id="cp">Copiar</button>
<pre id="c">${safe}</pre>
<button type="button" onclick="location.href='/'">Inicio</button>
<script>
var t=document.getElementById('c').innerText;
function cp(){navigator.clipboard.writeText(t).then(function(){alert('Copiado');}).catch(function(){var x=document.createElement('textarea');x.value=t;document.body.appendChild(x);x.select();document.execCommand('copy');document.body.removeChild(x);alert('Copiado');});}
document.getElementById('cp').onclick=cp; cp();
</script></body></html>`);
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Error: ' + e.message);
    }
  } else if (req.method === 'GET' && req.url.startsWith('/send')) {
    const base = `http://${req.headers.host || 'localhost'}`;
    const urlObj = new URL(req.url, base);
    if (urlObj.pathname !== '/send') {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('NOT FOUND');
    } else if (urlObj.searchParams.has('text')) {
      const text = urlObj.searchParams.get('text') || '';
      if (!text) {
        res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Missing text');
      } else if (Buffer.byteLength(text, 'utf8') > MAX_SFS_BYTES) {
        res.writeHead(413, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('PAYLOAD_TOO_LARGE');
      } else {
        try {
          ensureDir(OUT_DIR);
          const savedName = Date.now() + '.txt';
          fs.writeFileSync(path.join(OUT_DIR, savedName), text, 'utf8');
          log('SEND', 'OK', savedName);
          state.lastCommitTime = new Date().toISOString();
          sseBroadcast({
            kind: 'sfs',
            bucket: 'out',
            file: savedName,
            at: state.lastCommitTime
          });
          res.writeHead(200, {
            'Content-Type': 'text/plain; charset=utf-8',
            'X-Bridge-Filename': savedName
          });
          res.end('OK: ' + savedName);
        } catch (e) {
          log('SEND', 'ERROR', e.message);
          res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
          res.end('ERROR');
        }
      }
    } else {
      res.writeHead(302, { Location: '/?view=sender' });
      res.end();
    }
  } else if (req.method === 'POST' && req.url === '/upload') {
    const destHdr = (req.headers['x-dt-destination'] || 'out').toString().toLowerCase();
    const useIncoming = destHdr === 'incoming';
    const targetDir = useIncoming ? INCOMING_DIR : OUT_DIR;
    const label = useIncoming ? 'incoming' : 'out';
    postUploadHandler(req, res, targetDir, label, useIncoming ? 'incoming' : 'out');
  } else if (req.method === 'POST' && req.url === '/incoming') {
    postUploadHandler(req, res, INCOMING_DIR, 'incoming', 'incoming');
  } else if (req.method === 'POST' && req.url === '/clean-out') {
    cleanDirFiles(OUT_DIR, res);
  } else if (req.method === 'POST' && req.url === '/clean-incoming') {
    cleanDirFiles(INCOMING_DIR, res);
  } else if (req.method === 'GET' && req.url === '/health') {
    ensureDir(OUT_DIR);
    ensureDir(INCOMING_DIR);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(
      JSON.stringify({
        status: 'ok',
        app: 'data-transfer',
        role: 'dumb-transport',
        port: PORT,
        limits: {
          maxUploadBytes: MAX_UPLOAD_BYTES,
          maxSfsBytes: MAX_SFS_BYTES,
          maxReadBytes: MAX_READ_BYTES,
          maxUploadMb: CONFIG.maxUploadMb,
          maxSfsMb: CONFIG.maxSfsMb,
          maxReadMb: CONFIG.maxReadMb
        },
        paths: {
          out: OUT_DIR,
          incoming: INCOMING_DIR
        },
        outDirExists: fs.existsSync(OUT_DIR),
        incomingDirExists: fs.existsSync(INCOMING_DIR),
        timestamp: new Date().toISOString()
      })
    );
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('NOT FOUND');
  }
}

http.createServer(requestHandler).listen(PORT, '0.0.0.0', () => {
  ensureDir(OUT_DIR);
  ensureDir(INCOMING_DIR);
  const ip = getLocalIp();
  const url = 'http://' + ip + ':' + PORT;
  log('SERVER', 'LISTEN', url);
  console.log('==============================');
  console.log('Data transfer (dumb transport)', url);
  console.log('OUT:', OUT_DIR);
  console.log('INCOMING:', INCOMING_DIR);
  console.log('==============================');
  openDataTransferInBrowser('http://127.0.0.1:' + PORT);
});

module.exports = { requestHandler };
