// Agent color map
const AGENT_COLORS = {
    'DILEK': { color: '#06b6d4', emoji: '🎯', bg: 'rgba(6,182,212,0.12)' },
    'OB3-ProjectManager': { color: '#f59e0b', emoji: '📋', bg: 'rgba(245,158,11,0.12)' },
    'OB3-UXArchitect': { color: '#8b5cf6', emoji: '🏗️', bg: 'rgba(139,92,246,0.12)' },
    'OB3-UIDesigner': { color: '#ec4899', emoji: '🎨', bg: 'rgba(236,72,153,0.12)' },
    'OB3-SeniorDev': { color: '#3b82f6', emoji: '💻', bg: 'rgba(59,130,246,0.12)' },
    'OB3-MobileBuilder': { color: '#10b981', emoji: '📱', bg: 'rgba(16,185,129,0.12)' },
    'OB3-QA': { color: '#ef4444', emoji: '🧪', bg: 'rgba(239,68,68,0.12)' },
    'OB3-TechWriter': { color: '#f97316', emoji: '✍️', bg: 'rgba(249,115,22,0.12)' },
    'SYSTEM': { color: '#64748b', emoji: '⚙️', bg: 'rgba(100,116,139,0.12)' },
};

let lastMessageId = 0;
let pollInterval = null;
const seenAgents = new Set();

// --- Polling ---
async function pollMessages() {
    try {
        const res = await fetch(`/api/messages?since=${lastMessageId}`);
        const messages = await res.json();
        if (messages.length > 0) {
            messages.forEach(renderMessage);
            lastMessageId = messages[messages.length - 1].id;
            scrollToBottom();
        }
    } catch (e) {
        console.error('Poll error:', e);
    }
}

// --- Render ---
function renderMessage(msg) {
    const container = document.getElementById('messages');
    const agentInfo = AGENT_COLORS[msg.agent] || { color: '#94a3b8', emoji: '👤', bg: 'rgba(148,163,184,0.12)' };

    // Track active agents
    seenAgents.add(msg.agent);
    updateAgentList();

    const div = document.createElement('div');
    div.className = `msg ${msg.agent === 'SYSTEM' ? 'msg-system' : ''}`;

    if (msg.agent === 'SYSTEM') {
        div.innerHTML = `<div class="msg-body"><div class="msg-content">— ${escapeHTML(msg.content)} —</div></div>`;
    } else {
        const time = new Date(msg.timestamp).toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
        div.innerHTML = `
      <div class="msg-avatar" style="background: ${agentInfo.bg}; color: ${agentInfo.color}">${agentInfo.emoji}</div>
      <div class="msg-body">
        <div class="msg-header">
          <span class="msg-agent" style="color: ${agentInfo.color}">${escapeHTML(msg.agent)}</span>
          <span class="msg-type ${msg.type}">${msg.type}</span>
          <span class="msg-time">${time}</span>
        </div>
        <div class="msg-content">${escapeHTML(msg.content)}</div>
      </div>`;
    }

    container.appendChild(div);
}

function updateAgentList() {
    const list = document.getElementById('agentList');
    const count = document.getElementById('agentCount');
    count.textContent = `${seenAgents.size} agents active`;

    list.innerHTML = '';
    seenAgents.forEach(name => {
        const info = AGENT_COLORS[name] || { color: '#94a3b8', emoji: '👤' };
        const chip = document.createElement('div');
        chip.className = 'agent-chip';
        chip.innerHTML = `
      <span class="agent-dot" style="background: ${info.color}"></span>
      <span class="agent-chip-name">${info.emoji} ${name}</span>`;
        list.appendChild(chip);
    });
}

function scrollToBottom() {
    const el = document.getElementById('messages');
    el.scrollTop = el.scrollHeight;
}

function escapeHTML(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// --- Send ---
async function sendMessage() {
    const agent = document.getElementById('agentSelect').value;
    const content = document.getElementById('msgInput').value.trim();
    const type = document.getElementById('msgType').value;
    if (!content) return;

    try {
        await fetch('/api/message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ agent, content, type }),
        });
        document.getElementById('msgInput').value = '';
    } catch (e) {
        console.error('Send error:', e);
    }
}

async function clearChat() {
    if (!confirm('Clear all agent messages?')) return;
    await fetch('/api/clear', { method: 'POST' });
    document.getElementById('messages').innerHTML = '';
    lastMessageId = 0;
    seenAgents.clear();
    updateAgentList();
}

// --- Key handler ---
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('msgInput').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // Start polling
    pollMessages();
    pollInterval = setInterval(pollMessages, 1500);
});
