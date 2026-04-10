const fs = require('fs');
const fsp = require('fs/promises');

/**
 * Stream request body to disk; aborts if total bytes exceed maxBytes.
 * @returns {Promise<{ bytes: number }>}
 */
function streamBodyToFile(req, filePath, maxBytes) {
  return new Promise((resolve, reject) => {
    const ws = fs.createWriteStream(filePath);
    let total = 0;
    let finished = false;

    function fail(err) {
      if (finished) return;
      finished = true;
      try {
        req.destroy();
      } catch (e) {
        /* ignore */
      }
      ws.destroy();
      fsp.unlink(filePath).catch(() => {});
      reject(err);
    }

    req.on('data', (chunk) => {
      total += chunk.length;
      if (total > maxBytes) {
        fail(Object.assign(new Error('PAYLOAD_TOO_LARGE'), { code: 'PAYLOAD_TOO_LARGE' }));
        return;
      }
      if (!ws.write(chunk)) {
        req.pause();
        ws.once('drain', () => req.resume());
      }
    });

    req.on('end', () => {
      ws.end();
    });

    req.on('error', fail);
    ws.on('error', fail);
    ws.on('finish', () => {
      if (finished) return;
      finished = true;
      resolve({ bytes: total });
    });
  });
}

module.exports = { streamBodyToFile };
