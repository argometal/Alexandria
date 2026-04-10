const os = require('os');
const { execFile } = require('child_process');

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

module.exports = { getLocalIp, openDataTransferInBrowser };
