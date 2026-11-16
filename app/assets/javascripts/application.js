// Comportamentos simples da interface, em JavaScript puro (sem frameworks).

// Pede confirmação antes de ações sensíveis: <form data-confirm="Tem certeza?">
document.addEventListener("submit", (event) => {
  const message = event.target.dataset.confirm;
  if (message && !window.confirm(message)) event.preventDefault();
});
