const fs = require('fs');
const { HOWTO_FILE, PORT, OUT_DIR, INCOMING_DIR, CONFIG, ROOT_DIR } = require('./config');
const { buildAccessUrlRows, getLocalIp } = require('./utils');

function writeHowToFile() {
  const rows = buildAccessUrlRows(PORT);
  const urlBlock = rows.map((r) => `  ${r.url}  (${r.name}; ${r.kind})`).join('\n');
  const preferred = getLocalIp();
  const text = `================================================================================
DATA TRANSFER — transporte tonto (out/ + handoff/incoming/)
================================================================================

ARRANQUE
--------
  cd ${ROOT_DIR.replace(/\\/g, '\\\\')}
  node server.js

  Variables opcionales: DT_PORT, DT_MAX_UPLOAD_MB (def ${CONFIG.maxUploadMb}),
  DT_MAX_SFS_MB (def ${CONFIG.maxSfsMb}), DT_MAX_READ_MB (def ${CONFIG.maxReadMb})

  Puerto: ${PORT}

URL (todas las IPv4 de este equipo; prueba la que corresponda a tu red)
-----------------------------------------------------------------------
  IP preferida (log): ${preferred}

${urlBlock}

RUTAS (sin interpretar cuerpo)
------------------------------
  out/              ${OUT_DIR}
  incoming/         ${INCOMING_DIR}

  POST /sfs                    — texto → out/{ts}.txt (límite ${CONFIG.maxSfsMb} MiB)
  POST /upload                 — binario → out/ (nombre ts_original; o X-DT-Stable-Name: 1)
  POST /incoming               — binario → incoming/ (siempre ts_original)
  Cabecera: x-filename

  GET  /files?bucket=out|incoming
  GET  /read?name=&bucket=out|incoming   — vista texto cap ${CONFIG.maxReadMb} MiB
  GET  /download?name=&bucket=...
  GET  /send?text=...            — texto → out/
  GET  /latest?bucket=out|incoming
  GET  /health                   — límites, rutas y net.ipv4 (JSON)
  POST /clean-out                — borra archivos en out/
  POST /clean-incoming           — borra archivos en incoming/

  SSE GET /events
================================================================================
`;
  fs.writeFileSync(HOWTO_FILE, text, 'utf8');
}

module.exports = { writeHowToFile };
