async function loadCard() {
  // Extract ID from URL: /Bingo/<id>
  const parts = window.location.pathname.split("/");
  const cardId = parts[parts.length - 1];

  const response = await fetch("Bingo.json");
  const data = await response.json();

  const card = data.cards.find(c => c.id === cardId);
  if (!card) {
    document.body.innerHTML = "<h1>Card not found</h1>";
    return;
  }

  const numbers = card.card.split(",").map(Number);
  renderBingo(numbers);
}

function renderBingo(numbers) {
  const tbody = document.querySelector("#bingo tbody");
  tbody.innerHTML = "";

  for (let row = 0; row < 5; row++) {
    const tr = document.createElement("tr");

    for (let col = 0; col < 5; col++) {
      const index = row * 5 + col;
      const td = document.createElement("td");

      const value = numbers[index];
      if (value === 0) {
        td.textContent = "FREE";
        td.className = "free";
      } else {
        td.textContent = value;
      }

      tr.appendChild(td);
    }
    tbody.appendChild(tr);
  }
}

loadCard();
