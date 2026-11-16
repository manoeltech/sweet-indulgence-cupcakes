// Comportamentos simples da interface, em JavaScript puro (sem frameworks).

// Pede confirmação antes de ações sensíveis: <form data-confirm="Tem certeza?">
document.addEventListener("submit", (event) => {
  const message = event.target.dataset.confirm;
  if (message && !window.confirm(message)) event.preventDefault();
});

// Copia um texto para a área de transferência: <button data-copy="#pix">
document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-copy]");
  if (!button) return;
  const text = document.querySelector(button.dataset.copy).textContent.trim();
  navigator.clipboard.writeText(text).then(() => { button.textContent = "Copiado!"; });
});

// Checkout: mostra os campos certos para entrega/retirada e cartão/PIX e atualiza o frete e o total.
document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector("[data-checkout]");
  if (!form) return;

  const field = (name) => form.elements[`checkout[${name}]`];
  const toggle = (id, hidden) => document.getElementById(id).classList.toggle("oculto", hidden);
  const brl = (value) => value.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  const totalCell = document.getElementById("total");

  function update() {
    const delivery = field("fulfillment").value === "delivery";
    const pix = field("payment_method").value === "pix";
    toggle("bloco-entrega", !delivery);
    toggle("bloco-retirada", delivery);
    toggle("bloco-cartao", pix);
    toggle("bloco-pix", !pix);

    const zone = field("delivery_zone_id").selectedOptions[0];
    const fee = delivery && zone && zone.dataset.fee ? parseFloat(zone.dataset.fee) : 0;
    document.getElementById("frete").textContent = !delivery ? "Grátis" : (zone && zone.dataset.fee ? brl(fee) : "escolha o bairro");
    totalCell.textContent = brl(parseFloat(totalCell.dataset.base) + fee);

    const saved = field("saved_address_id");
    if (saved) field("address").disabled = delivery && saved.value !== "";
  }

  form.addEventListener("change", update);
  update();
});
