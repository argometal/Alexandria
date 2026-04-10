function log(component, action, data = '') {
  const timestamp = new Date().toISOString().slice(11, 19);
  console.log(`[${timestamp}][DT][${component}] ${action} ${data}`);
}

module.exports = { log };
