const os = require('os');
const path = require('path');
const { execFile, spawn } = require('child_process');

function getLocalIp() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return '127.0.0.1';
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
        windowsHide: true,
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

module.exports = { getLocalIp, openDataTransferInBrowser, openLocalFolder, folderPathForFileManager };
