let currentCardId = null;
let punchState = [];

async function loadCard() {
  // URL format: /Bingo/<cardId>
  const parts = window.location.pathname.split("/").filter(Boolean);
  currentCardId = parts[parts.length - 1];

  try {
    const response = await fetch("Bingo.json");
    const data = await response.json();

    const card = data.cards.find(c => c.id === currentCardId);
    if (!card) {
      document.body.innerHTML = "<h1>Card not found</h1>";
      return;
    }

    const numbers = card.card.split(",").map(Number);

    loadPunchState();
    renderBingo(numbers);
  } catch (err) {
    document.body.innerHTML = "<h1>Error loading Bingo.json</h1>";
  }
}

function storageKey() {
  return `bingo:${currentCardId}`;
}

function loadPunchState() {
  const stored = localStorage.getItem(storageKey());
  if (stored) {
    punchState = JSON.parse(stored);
  } else {
    // default: all unpunched
    punchState = Array(25).fill(false);
  }
}

function savePunchState() {
  localStorage.setItem(storageKey(), JSON.stringify(punchState));
}

function renderBingo(numbers) {
  const tbody = document.querySelector("#bingo tbody");
  tbody.innerHTML = "";

  for (let row = 0; row < 5; row++) {
    const tr = document.createElement("tr");

    for (let col = 0; col < 5; col++) {
      const td = document.createElement("td");

      // Column-major index
      const index = col * 5 + row;
      const value = numbers[index];

      if (value === 0) {
        td.textContent = "FREE";
        td.classList.add("free", "punched");
        punchState[index] = true;
      } else {
        td.textContent = value;

        if (punchState[index]) {
          td.classList.add("punched");
        }

        td.addEventListener("click", () => {
          punchState[index] = !punchState[index];
          td.classList.toggle("punched");
          savePunchState();
        });
      }

      tr.appendChild(td);
    }

    tbody.appendChild(tr);
  }

  savePunchState();
}

document.getElementById("reset").addEventListener("click", () => {
  punchState = Array(25).fill(false);
  localStorage.removeItem(storageKey());
  loadCard();
});

loadCard();
