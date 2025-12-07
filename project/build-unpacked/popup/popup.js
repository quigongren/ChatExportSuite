// popup.js – Chat Export Suite v3.2

function setStatus(msg) {
  const el = document.getElementById('status');
  if (el) el.textContent = msg || '';
}

async function requestExport(format, suppressDownload) {
  setStatus('Collecting messages…');

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab) {
    setStatus('No active tab.');
    return null;
  }

  return new Promise((resolve) => {
    chrome.tabs.sendMessage(
      tab.id,
      { type: 'CES_EXPORT', format },
      (resp) => {
        if (chrome.runtime.lastError) {
          console.error('ChatExportSuite error', chrome.runtime.lastError);
          setStatus('Could not reach page. Is this ChatGPT?');
          resolve(null);
          return;
        }
        if (!resp || !resp.ok) {
          console.error('ChatExportSuite response error', resp);
          setStatus(resp && resp.error ? resp.error : 'Export failed.');
          resolve(null);
          return;
        }

        // PDF uses print window directly from the content script
        if (format === 'pdf') {
          setStatus('Print dialog opened. Use “Save as PDF”.');
          resolve(resp);
          return;
        }

        if (!suppressDownload) {
          // For text/html/markdown: create a download
          let filename = 'chat-export.txt';
          let mime = 'text/plain;charset=utf-8';
          if (format === 'markdown') {
            filename = 'chat-export.md';
            mime = 'text/markdown;charset=utf-8';
          } else if (format === 'html') {
            filename = 'chat-export.html';
            mime = 'text/html;charset=utf-8';
          }
          const blob = new Blob([resp.content], { type: mime });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = filename;
          document.body.appendChild(a);
          a.click();
          a.remove();
          URL.revokeObjectURL(url);
          setStatus('Downloaded ' + filename);
        }

        resolve(resp);
      }
    );
  });
}

document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-pdf').addEventListener('click', () => {
    requestExport('pdf', true);
  });

  document.getElementById('btn-html').addEventListener('click', () => {
    requestExport('html', false);
  });

  document.getElementById('btn-md').addEventListener('click', () => {
    requestExport('markdown', false);
  });

  document.getElementById('btn-txt').addEventListener('click', () => {
    requestExport('text', false);
  });

  document.getElementById('btn-docx').addEventListener('click', async () => {
    const resp = await requestExport('markdown', false);
    if (!resp) return;

    // Show notification hinting at macOS helpers
    if (chrome.notifications) {
      chrome.notifications.create({
        type: 'basic',
        iconUrl: chrome.runtime.getURL('icon48.png'),
        title: 'Chat Export Suite',
        message:
          'Markdown exported as chat-export.md.\nUse your macOS Quick Action or DOCX Converter app to generate Word (.docx).'
      });
    }

    // Optionally open downloads page for convenience
    chrome.tabs.create({ url: 'chrome://downloads/' });
    setStatus('Markdown exported for DOCX conversion.');
  });

  const optionsLink = document.getElementById('options-link');
  optionsLink.addEventListener('click', (e) => {
    e.preventDefault();
    chrome.runtime.openOptionsPage();
  });
});
