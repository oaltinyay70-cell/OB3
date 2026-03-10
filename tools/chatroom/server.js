const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3847;
const CHAT_FILE = path.join(__dirname, 'messages.json');

// Initialize messages file if it doesn't exist
if (!fs.existsSync(CHAT_FILE)) {
  fs.writeFileSync(CHAT_FILE, JSON.stringify([], null, 2));
}

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
};

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // POST /api/message — agents post messages here
  if (req.method === 'POST' && req.url === '/api/message') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const msg = JSON.parse(body);
        if (!msg.agent || !msg.content) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Missing agent or content' }));
          return;
        }
        const messages = JSON.parse(fs.readFileSync(CHAT_FILE, 'utf8'));
        const entry = {
          id: messages.length + 1,
          agent: msg.agent,
          content: msg.content,
          type: msg.type || 'message',
          to: msg.to || null,
          timestamp: new Date().toISOString(),
        };
        messages.push(entry);
        fs.writeFileSync(CHAT_FILE, JSON.stringify(messages, null, 2));
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(entry));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // GET /api/messages?since=ID — poll for new messages
  if (req.method === 'GET' && req.url.startsWith('/api/messages')) {
    const url = new URL(req.url, `http://localhost:${PORT}`);
    const since = parseInt(url.searchParams.get('since') || '0', 10);
    const messages = JSON.parse(fs.readFileSync(CHAT_FILE, 'utf8'));
    const filtered = messages.filter(m => m.id > since);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(filtered));
    return;
  }

  // POST /api/clear — clear all messages
  if (req.method === 'POST' && req.url === '/api/clear') {
    fs.writeFileSync(CHAT_FILE, JSON.stringify([], null, 2));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'cleared' }));
    return;
  }

  // Serve agent DM pages: /agent/AGENT_NAME
  if (req.method === 'GET' && req.url.startsWith('/agent/')) {
    const agentPage = path.join(__dirname, 'agent.html');
    fs.readFile(agentPage, (err, data) => {
      if (err) { res.writeHead(404); res.end('Not found'); return; }
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(data);
    });
    return;
  }

  // Serve static files
  let filePath = req.url === '/' ? '/index.html' : req.url;
  filePath = path.join(__dirname, filePath);
  const ext = path.extname(filePath);
  const contentType = MIME_TYPES[ext] || 'text/plain';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`🎯 OB3 Agent Chatroom running at http://localhost:${PORT}`);
  console.log(`   Messages stored in: ${CHAT_FILE}`);
});
