/*!
  File: search-button.js
  Author: maxJOT, 10-MAR-2026
 */

document.addEventListener('DOMContentLoaded', function () {
  const input = document.getElementById('search-input');
  const field = document.getElementById('search-field');

  if (!input || !field) return;

  const clearBtn = document.createElement('span');
  clearBtn.id = 'search-clear';
  clearBtn.textContent = 'X';
  clearBtn.style.display = 'none';

  field.appendChild(clearBtn);

  input.addEventListener('input', function () {
    if (input.value) {
      clearBtn.style.display = 'block';
      field.classList.add('has-text');
    } else {
      clearBtn.style.display = 'none';
      field.classList.remove('has-text');
    }
  });

  clearBtn.addEventListener('click', function () {
    input.value = '';
    clearBtn.style.display = 'none';
    field.classList.remove('has-text');
    input.focus();
  });
});