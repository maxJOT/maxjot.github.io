/*!
  File: search-button.js
  Author: maxJOT, 10-MAR-2026
*/

document.addEventListener('DOMContentLoaded', function () {
  const input = document.getElementById('search-input');
  const field = document.getElementById('search-field');

  if (!input || !field) return;

  // --- Clear input on page load ---
  input.value = '';

  const clearBtn = document.createElement('span');
  clearBtn.id = 'search-clear';
  clearBtn.textContent = 'X';
  clearBtn.style.display = 'none';

  field.appendChild(clearBtn);

  // --- Show/hide clear button & magnifier ---
  input.addEventListener('input', function () {
    if (input.value) {
      clearBtn.style.display = 'block';
      field.classList.add('has-text'); // hides magnifier via CSS
    } else {
      clearBtn.style.display = 'none';
      field.classList.remove('has-text'); // shows magnifier again
    }
  });

  // --- Clear button click ---
  clearBtn.addEventListener('click', function () {
    input.value = '';
    clearBtn.style.display = 'none';
    field.classList.remove('has-text'); // show magnifier
    input.focus();
  });
});