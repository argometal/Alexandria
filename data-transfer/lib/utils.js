const os = require('os');
const path = require('path');
const { execFile, spawn } = require('child_process');

/**
 * Clasifica la interfaz para ordenar y etiquetar (troubleshooting).
 * @param {string} name
 * @param {string} address
 * @param {boolean} internal
 * @returns {'loopback'|'wireless'|'wired'|'virtual'|'other'}
 */
function classifyInterface(name, address, internal) {
  const n = (name || '').toLowerCase();
  const a = address || '';
  if (internal || /^127\./.test(a)) return 'loopback';
  if (
    /wi-?fi|wlan|wireless|802\.11|inalambrica|inalámbrica|conexión de red inalambrica|conexión de red inalámbrica/.test(
      n
    )
  ) {
    return 'wireless';
  }
  if (
    /vethernet|hyper-v|wsl|docker|virtualbox|vmware|npcap|tailscale|zerotier|tun|tap|vbox|virtual|vmnet|bridge|vEthernet|default switch|minipuerto|miniport|pseudo|teredo|isatap|bluetooth pan/.test(
      n
    )
  ) {
    return 'virtual';
  }
  if (/ethernet|eth[0-9]|en[0-9]|\blan\b|gigabit|placa de red|conexión de área local/.test(n)) {
    return 'wired';
  }
  return 'other';
}

/**
 * Todas las direcciones IPv4 con nombre de interfaz (Node puede reportar family como 4 o 'IPv4').
 * @returns {{name:string,address:string,internal:boolean,kind:string}[]}
 */
function listIPv4Endpoints() {
  const nets = os.networkInterfaces();
  const out = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      const fam = net.family;
      if (fam !== 'IPv4' && fam !== 4) continue;
      const address = net.address || '';
      const internal = !!net.internal;
      const kind = classifyInterface(name, address, internal);
      out.push({ name: name || '(unnamed)', address, internal, kind });
    }
  }
  const rank = { loopback: 0, wireless: 1, wired: 2, other: 3, virtual: 9 };
  out.sort((a, b) => rank[a.kind] - rank[b.kind] || a.name.localeCompare(b.name));
  return out;
}

/**
 * Filas únicas por IP para la UI (una URL por dirección; orden amigable).
 * @param {number} port
 * @returns {{name:string,address:string,kind:string,url:string}[]}
 */
function buildAccessUrlRows(port) {
  const seen = new Set();
  const rows = [];
  for (const e of listIPv4Endpoints()) {
    if (!e.address || seen.has(e.address)) continue;
    seen.add(e.address);
    rows.push({
      name: e.name,
      address: e.address,
      kind: e.kind,
      url: 'http://' + e.address + ':' + port
    });
  }
  if (!seen.has('127.0.0.1')) {
    rows.unshift({
      name: '127.0.0.1',
      address: '127.0.0.1',
      kind: 'loopback',
      url: 'http://127.0.0.1:' + port
    });
  }
  return rows;
}

/**
 * Una IP “preferida” para logs / HOW_TO compacto: Wi‑Fi > cable > no virtual > primera.
 */
function getLocalIp() {
  const eps = listIPv4Endpoints().filter((e) => !e.internal && !/^127\./.test(e.address));
  const pick = (k) => eps.find((e) => e.kind === k);
  return (pick('wireless') || pick('wired') || eps.find((e) => e.kind !== 'virtual') || eps[0])?.address || '127.0.0.1';
}

function openDataTransferInBrowser(url) {
  if (process.platform !== 'win32') return;
  try {
    execFile('cmd', ['/c', 'start', '', url], { windowsHide: true }, () => {});
  } catch (e) {
    /* ignore */
  }
}

/** Normalize directory path for OS file manager (strip trailing sep except drive / root). */
function folderPathForFileManager(dirPath) {
  let p = path.resolve(dirPath);
  while (p.length > 1 && p.endsWith(path.sep)) {
    const next = p.slice(0, -1);
    if (process.platform === 'win32' && /^[A-Za-z]:$/.test(next)) break;
    p = next;
  }
  return p;
}

/**
 * Opens a folder in the desktop file manager (local machine only — call from loopback).
 * @returns {Promise<void>}
 */
function openLocalFolder(dirPath) {
  const p = folderPathForFileManager(dirPath);
  const platform = process.platform;

  // Windows: `explorer` often exits with code 1 even when the window opened; `execFile` then
  // reports Command failed. Spawn detached and treat successful start as OK.
  if (platform === 'win32') {
    return new Promise((resolve, reject) => {
      const explorerExe = path.join(process.env.SystemRoot || 'C:\\Windows', 'explorer.exe');
      const child = spawn(explorerExe, [p], {
        detached: true,
        stdio: 'ignore',
        windowsHide: true
      });
      child.once('error', reject);
      child.once('spawn', () => {
        child.unref();
        resolve();
      });
    });
  }

  let cmd;
  let args;
  if (platform === 'darwin') {
    cmd = 'open';
    args = [p];
  } else {
    cmd = 'xdg-open';
    args = [p];
  }
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { windowsHide: true }, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });
}

module.exports = {
  classifyInterface,
  listIPv4Endpoints,
  buildAccessUrlRows,
  getLocalIp,
  openDataTransferInBrowser,
  openLocalFolder,
  folderPathForFileManager
};
