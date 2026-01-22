/*!
  File: coderunner.js
  Author: maxJOT, 06-JAN-2025
 */


function highlightCharacters(codeElement) {
  // Run only once.
  if (codeElement.dataset.crProcessed) return;
  codeElement.dataset.crProcessed = "true";
  const map = {
    '"': 'cr-double-quote',
    "'": 'cr-single-quote',
    '{': 'cr-brace-open',
    '}': 'cr-brace-close',
    '[': 'cr-bracket-open',
    ']': 'cr-bracket-close',
    '(': 'cr-paren-open',
    ')': 'cr-paren-close',
    '`': 'cr-backtick',
    '>': 'cr-greater',
    '<': 'cr-smaller',
    '&': 'cr-ampersand',
    '|': 'cr-pipe',
    '$': 'cr-dollar',
    ';': 'cr-semicolon'
  };

  const walker = document.createTreeWalker(
    codeElement,
    NodeFilter.SHOW_TEXT,
    null
  );

  const textNodes = [];
  while (walker.nextNode()) {
    textNodes.push(walker.currentNode);
  }

  textNodes.forEach(node => {
    const frag = document.createDocumentFragment();

    for (const ch of node.nodeValue) {
      if (map[ch]) {
        const span = document.createElement('span');
        span.className = map[ch];
        span.textContent = ch;
        frag.appendChild(span);
      } else {
        frag.appendChild(document.createTextNode(ch));
      }
    }

    node.replaceWith(frag);
  });
}
