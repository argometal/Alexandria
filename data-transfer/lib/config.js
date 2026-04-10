const path = require('path');

const ROOT_DIR = path.join(__dirname, '..');

function envInt(name, def) {
  const v = process.env[name];
  if (v == null || v === '') return def;
  const n = parseInt(v, 10);
  return Number.isFinite(n) && n > 0 ? n : def;
}

function mbToBytes(mb) {
  return Math.floor(mb * 1024 * 1024);
}

/** Max single POST /upload or /incoming (aligns with ~pack zip margin over 50 MiB spec). */
const MAX_UPLOAD_MB = envInt('DT_MAX_UPLOAD_MB', 52);
/** Max POST /sfs body (text). */
const MAX_SFS_MB = envInt('DT_MAX_SFS_MB', 10);
/** Max bytes served as inline text for /read and /latest (avoid loading huge zips into RAM). */
const MAX_READ_MB = envInt('DT_MAX_READ_MB', 2);

const MAX_UPLOAD_BYTES = mbToBytes(MAX_UPLOAD_MB);
const MAX_SFS_BYTES = mbToBytes(MAX_SFS_MB);
const MAX_READ_BYTES = mbToBytes(MAX_READ_MB);

const OUT_DIR = path.join(ROOT_DIR, 'out') + path.sep;
const INCOMING_DIR = path.join(ROOT_DIR, 'handoff', 'incoming') + path.sep;
const HOWTO_FILE = path.join(ROOT_DIR, 'HOW_TO_USE.txt');

const CONFIG = {
  port: envInt('DT_PORT', 4020),
  outDir: OUT_DIR,
  incomingDir: INCOMING_DIR,
  howtoFile: HOWTO_FILE,
  maxUploadBytes: MAX_UPLOAD_BYTES,
  maxSfsBytes: MAX_SFS_BYTES,
  maxReadBytes: MAX_READ_BYTES,
  maxUploadMb: MAX_UPLOAD_MB,
  maxSfsMb: MAX_SFS_MB,
  maxReadMb: MAX_READ_MB
};

const PORT = CONFIG.port;

function bucketDir(bucket) {
  const b = (bucket || 'out').toString().toLowerCase();
  if (b === 'incoming') return INCOMING_DIR;
  return OUT_DIR;
}

module.exports = {
  CONFIG,
  PORT,
  OUT_DIR,
  INCOMING_DIR,
  HOWTO_FILE,
  ROOT_DIR,
  MAX_UPLOAD_BYTES,
  MAX_SFS_BYTES,
  MAX_READ_BYTES,
  bucketDir
};
