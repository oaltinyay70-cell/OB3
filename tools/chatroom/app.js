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
    'COMMANDER': { color: '#facc15', emoji: '👤', bg: 'rgba(250,204,21,0.12)' },
};

let lastMessageId = 0;
let pollInterval = null;
const seenAgents = new Set();
let currentChannel = 'general'; // 'general' or agent name

// --- Channel Management ---
function switchChannel(channel) {
    currentChannel = channel;

    // Update sidebar active state
    document.querySelectorAll('.agent-chip').forEach(chip => {
        chip.classList.remove('active');
    });
    const activeChip = document.querySelector(`.agent-chip[data-channel="${channel}"]`);
    if (activeChip) activeChip.classList.add('active');

    // Update header
    const channelName = document.getElementById('channelName');
    if (channel === 'general') {
        channelName.textContent = '# GENERAL';
        channelName.style.color = 'var(--text-primary)';
    } else {
        const info = AGENT_COLORS[channel] || { emoji: '👤', color: '#94a3b8' };
        channelName.textContent = `${info.emoji} ${channel}`;
        channelName.style.color = info.color;
    }

    // Update agent select in input to match channel
    const select = document.getElementById('agentSelect');
    if (channel !== 'general' && channel !== 'COMMANDER') {
        select.value = channel;
    }

    // Re-render messages for this channel
    renderAllMessages();
}

// --- Polling ---
let allMessages = [];

async function pollMessages() {
    try {
        const res = await fetch(`/api/messages?since=${lastMessageId}`);
        const messages = await res.json();
        if (messages.length > 0) {
            messages.forEach(msg => {
                allMessages.push(msg);
                seenAgents.add(msg.agent);
            });
            lastMessageId = allMessages[allMessages.length - 1].id;
            updateAgentList();
            renderAllMessages();
        }
    } catch (e) {
        console.error('Poll error:', e);
    }
}

// --- Render ---
function renderAllMessages() {
    const container = document.getElementById('messages');
    container.innerHTML = '';

    const filtered = currentChannel === 'general'
        ? allMessages
        : allMessages.filter(m =>
            m.agent === currentChannel ||
            m.to === currentChannel ||
            (m.agent === 'COMMANDER' && m.to === currentChannel)
        );

    filtered.forEach(msg => renderMessage(msg, container));
    scrollToBottom();
}

function renderMessage(msg, container) {
    const agentInfo = AGENT_COLORS[msg.agent] || { color: '#94a3b8', emoji: '👤', bg: 'rgba(148,163,184,0.12)' };

    const div = document.createElement('div');
    div.className = `msg ${msg.agent === 'SYSTEM' ? 'msg-system' : ''}`;

    if (msg.agent === 'SYSTEM') {
        div.innerHTML = `<div class="msg-body"><div class="msg-content">— ${escapeHTML(msg.content)} —</div></div>`;
    } else {
        const time = new Date(msg.timestamp).toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
        const toTag = msg.to ? `<span class="msg-to">→ ${msg.to}</span>` : '';
        div.innerHTML = `
      <div class="msg-avatar" style="background: ${agentInfo.bg}; color: ${agentInfo.color}">${agentInfo.emoji}</div>
      <div class="msg-body">
        <div class="msg-header">
          <span class="msg-agent" style="color: ${agentInfo.color}">${escapeHTML(msg.agent)}</span>
          ${toTag}
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
    count.textContent = `${seenAgents.size} agents`;

    list.innerHTML = '';

    // General channel
    const genChip = document.createElement('div');
    genChip.className = `agent-chip ${currentChannel === 'general' ? 'active' : ''}`;
    genChip.dataset.channel = 'general';
    genChip.onclick = () => switchChannel('general');
    genChip.innerHTML = `
    <span class="agent-dot" style="background: var(--accent-cyan)"></span>
    <span class="agent-chip-name"># General</span>
    <span class="agent-chip-count">${allMessages.length}</span>`;
    list.appendChild(genChip);

    // Divider
    const divider = document.createElement('div');
    divider.className = 'sidebar-divider';
    divider.textContent = 'DIRECT MESSAGES';
    list.appendChild(divider);

    // Agent channels
    const agents = ['DILEK', 'OB3-ProjectManager', 'OB3-UXArchitect', 'OB3-UIDesigner',
        'OB3-SeniorDev', 'OB3-MobileBuilder', 'OB3-QA', 'OB3-TechWriter'];

    agents.forEach(name => {
        const info = AGENT_COLORS[name] || { color: '#94a3b8', emoji: '👤' };
        const msgCount = allMessages.filter(m => m.agent === name || m.to === name).length;
        const chip = document.createElement('div');
        chip.className = `agent-chip ${currentChannel === name ? 'active' : ''}`;
        chip.dataset.channel = name;
        chip.onclick = () => switchChannel(name);
        chip.innerHTML = `
      <span class="agent-dot" style="background: ${info.color}"></span>
      <span class="agent-chip-name">${info.emoji} ${name.replace('OB3-', '')}</span>
      ${msgCount > 0 ? `<span class="agent-chip-count">${msgCount}</span>` : ''}`;
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
    const content = document.getElementById('msgInput').value.trim();
    const type = document.getElementById('msgType').value;
    if (!content) return;

    // If in a DM channel, send as COMMANDER to that agent
    let agent, to;
    if (currentChannel !== 'general') {
        agent = 'COMMANDER';
        to = currentChannel;
    } else {
        agent = document.getElementById('agentSelect').value;
        to = undefined;
    }

    try {
        await fetch('/api/message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ agent, content, type, to }),
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
    allMessages = [];
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

    // Initial render
    updateAgentList();

    // Start polling
    pollMessages();
    pollInterval = setInterval(pollMessages, 1500);
});
