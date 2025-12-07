// export-print.js – used only when opening PDF window
window.addEventListener('load', () => {
  try {
    window.print();
  } catch (e) {
    console.error('Chat Export Suite print error', e);
  }
});
