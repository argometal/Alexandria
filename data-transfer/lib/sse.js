const state = require('./state');

function sseBroadcast(obj) {
  const line = 'data: ' + JSON.stringify(obj) + '\n\n';
  for (const client of state.sseClients) {
    try {
      client.write(line);
    } catch (e) {
      state.sseClients.delete(client);
    }
  }
}

module.exports = { sseBroadcast };
