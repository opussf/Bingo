async function loadCard() {
  // URL format: /Bingo/<cardId>
  const parts = window.location.pathname.split("/").filter(Boolean);
  const cardId = parts[parts.length - 1];

  try {
    const response = await fetch("Bingo.json");
    const data = await response.json();

    const card = data.cards.find(c => c.id === cardId);
    if (!card) {
      document.body.innerHTML = "<h1>Card not found</h1>";
      return;
    }

    const numbers = card.card.split(",").map(Number);
    renderBingo(numbers);
  } catch (err) {
    document.body.innerHTML = "<h1>Error loading Bingo.json</h1>";
  }
}

function renderBingo(numbers) {
  const tbody = document.querySelector("#bingo tbody");
  tbody.innerHTML = "";

  for (let row = 0; row < 5; row++) {
    const tr = document.createElement("tr");

    for (let col = 0; col < 5; col++) {
      const td = document.createElement("td");

      // COLUMN-MAJOR mapping (top → bottom, left → right)
      const value = numbers[col * 5 + row];

      if (value === 0) {
        td.textContent = "FREE";
        td.classList.add("free", "punched");
      } else {
        td.textContent = value;

        td.addEventListener("click", () => {
          td.classList.toggle("punched");
        });
      }

      tr.appendChild(td);
    }

    tbody.appendChild(tr);
  }
}

document.getElementById("reset").addEventListener("click", () => {
  document.querySelectorAll("#bingo td").forEach(td => {
    if (!td.classList.contains("free")) {
      td.classList.remove("punched");
    }
  });
});

loadCard();
