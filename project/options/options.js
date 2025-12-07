// options.js – Chat Export Suite selector options

const DEFAULT_PROFILE = {
  messageSelector: 'div[data-message-author-role]',
  roleAttr: 'data-message-author-role'
};

function loadProfile() {
  chrome.storage.sync.get(['cesProfile'], (data) => {
    const profile = data.cesProfile || DEFAULT_PROFILE;
    document.getElementById('messageSelector').value = profile.messageSelector;
    document.getElementById('roleAttr').value = profile.roleAttr;
  });
}

function saveProfile() {
  const profile = {
    messageSelector:
      document.getElementById('messageSelector').value.trim() ||
      DEFAULT_PROFILE.messageSelector,
    roleAttr:
      document.getElementById('roleAttr').value.trim() || DEFAULT_PROFILE.roleAttr
  };
  chrome.storage.sync.set({ cesProfile: profile }, () => {
    alert('Saved.');
  });
}

function resetProfile() {
  chrome.storage.sync.remove(['cesProfile'], () => {
    loadProfile();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadProfile();
  document.getElementById('save').addEventListener('click', saveProfile);
  document.getElementById('reset').addEventListener('click', resetProfile);
});
