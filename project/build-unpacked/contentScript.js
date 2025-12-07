// Chat Export Suite v3.2 – contentScript.js

const CES_DEFAULT_PROFILE = {
  messageSelector: 'div[data-message-author-role]',
  roleAttr: 'data-message-author-role'
};

let cesActiveProfile = { ...CES_DEFAULT_PROFILE };
let cesProfileLoaded = false;

function cesLoadProfile() {
  return new Promise((resolve) => {
    if (cesProfileLoaded) {
      resolve();
      return;
    }
    chrome.storage.sync.get(['cesProfile'], (data) => {
      if (data && data.cesProfile) {
        cesActiveProfile = { ...CES_DEFAULT_PROFILE, ...data.cesProfile };
      }
      cesProfileLoaded = true;
      resolve();
    });
  });
}

function cesGetMessages() {
  const nodes = document.querySelectorAll(cesActiveProfile.messageSelector);
  const messages = [];
  nodes.forEach((el) => {
    const role = el.getAttribute(cesActiveProfile.roleAttr) || 'unknown';
    const text = el.innerText.trim();
    if (!text) return;
    messages.push({ role, text });
  });
  return messages;
}

function cesBuildOutputs(messages) {
  const textOut = messages
    .map((m) => `${m.role.toUpperCase()}:\n${m.text}\n`)
    .join('\n');

  const mdOut = messages
    .map((m) => `### ${m.role.toUpperCase()}\n\n${m.text}\n`)
    .join('\n');

  const htmlBody = messages
    .map(
      (m) =>
        `<section class="msg"><h3>${m.role.toUpperCase()}</h3><pre>${m.text
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')}</pre></section>`
    )
    .join('\n');

  const htmlOut = `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Chat Export</title>
  <style>
    body { font-family: -apple-system,BlinkMacSystemFont,system-ui,sans-serif; padding: 24px; background: #0b1120; color: #e5e7eb; }
    .msg { margin-bottom: 16px; padding: 12px 16px; border-radius: 10px; background: #020617; border: 1px solid #1f2937; }
    h3 { margin: 0 0 6px; font-size: 12px; letter-spacing: 0.08em; opacity: 0.8; }
    pre { margin: 0; white-space: pre-wrap; line-height: 1.5; font-size: 13px; }
  </style>
</head>
<body>
${htmlBody}
<script src="${chrome.runtime.getURL('export-print.js')}"></script>
</body>
</html>`;

  return { textOut, mdOut, htmlOut };
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (!msg || msg.type !== 'CES_EXPORT') return;

  (async () => {
    await cesLoadProfile();
    const messages = cesGetMessages();
    if (!messages.length) {
      sendResponse({ ok: false, error: 'No messages found.' });
      return;
    }

    const { textOut, mdOut, htmlOut } = cesBuildOutputs(messages);

    if (msg.format === 'pdf') {
      const win = window.open('', '_blank');
      if (!win) {
        sendResponse({ ok: false, error: 'Popup blocked.' });
        return;
      }
      win.document.open();
      win.document.write(htmlOut);
      win.document.close();
      sendResponse({ ok: true, format: 'pdf' });
      return;
    }

    if (msg.format === 'text') {
      sendResponse({ ok: true, format: 'text', content: textOut });
      return;
    }
    if (msg.format === 'markdown') {
      sendResponse({ ok: true, format: 'markdown', content: mdOut });
      return;
    }
    if (msg.format === 'html') {
      sendResponse({ ok: true, format: 'html', content: htmlOut });
      return;
    }

    sendResponse({ ok: false, error: 'Unknown export format.' });
  })();

  return true;
});
