let activeCardIds = [];

async function loadCards() {
  // URL format: /Bingo/<id>[,<id>...]
  const parts = window.location.pathname.split("/").filter(Boolean);
  const idPart = parts[parts.length - 1];

  activeCardIds = idPart.split(",").slice(0, 10);

  const response = await fetch("Bingo.json");
  const data = await response.json();

  const container = document.getElementById("cards");
  container.innerHTML = "";

  for (const cardId of activeCardIds) {
    const cardData = data.cards.find(c => c.id === cardId);
    if (!cardData) continue;

    renderCard(container, cardId, cardData.card);
  }
}

function storageKey(cardId) {
  return `bingo:${cardId}`;
}

function loadPunchState(cardId) {
  const stored = localStorage.getItem(storageKey(cardId));
  return stored ? JSON.parse(stored) : Array(25).fill(false);
}

function savePunchState(cardId, state) {
  localStorage.setItem(storageKey(cardId), JSON.stringify(state));
}

function renderCard(container, cardId, csv) {
  const numbers = csv.split(",").map(Number);
  let punchState = loadPunchState(cardId);

  const wrapper = document.createElement("div");
  wrapper.className = "card";

  // --- Header: Reset button left, Card ID right ---
  const header = document.createElement("div");
  header.className = "card-header";

  const reset = document.createElement("button");
  reset.textContent = "Reset";
  reset.onclick = () => {
    punchState = Array(25).fill(false);
    localStorage.removeItem(storageKey(cardId));
    loadCards();
  };

  const title = document.createElement("div");
  title.textContent = `Card ID: ${cardId}`;
  title.className = "card-id";

  header.appendChild(reset);
  header.appendChild(title);
  wrapper.appendChild(header);

  // --- Table ---
  const table = document.createElement("table");
  table.innerHTML = `
    <thead>
      <tr>
        <th>B</th><th>I</th><th>N</th><th>G</th><th>O</th>
      </tr>
    </thead>
    <tbody></tbody>
  `;
  const tbody = table.querySelector("tbody");

  for (let row = 0; row < 5; row++) {
    const tr = document.createElement("tr");
    for (let col = 0; col < 5; col++) {
      const index = col * 5 + row;
      const value = numbers[index];
      const td = document.createElement("td");

      if (value === 0) {
        td.textContent = "FREE";
        td.classList.add("free", "punched");
        punchState[index] = true;
      } else {
        td.textContent = value;
        if (punchState[index]) td.classList.add("punched");

        td.onclick = () => {
          punchState[index] = !punchState[index];
          td.classList.toggle("punched");
          savePunchState(cardId, punchState);
        };
      }
      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }

  savePunchState(cardId, punchState);

  wrapper.appendChild(table);
  container.appendChild(wrapper);
}

/* ---------- GLOBAL RESET ---------- */

document.getElementById("global-reset").addEventListener("click", () => {
  for (const cardId of activeCardIds) {
    localStorage.removeItem(storageKey(cardId));
  }
  loadCards();
});

loadCards();
