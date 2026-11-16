"""Gateway de pagamento SIMULADO.

O US08 pede um gateway certificado (PCI-DSS). Integrar um gateway real exige conta
comercial e chaves de produção, então nesta entrega o pagamento é simulado com as mesmas
regras de um gateway de testes. Trocar por um gateway real só muda esta classe.

Cartões de teste:
  4111 1111 1111 1111 -> aprovado
  4000 0000 0000 0002 -> recusado (exercita o fluxo alternativo CU01-B)
"""
import secrets
from dataclasses import dataclass
from datetime import date

from .models.pedido import RegraNegocioErro

CARTAO_RECUSADO = "4000000000000002"


@dataclass
class ResultadoCobranca:
    aprovado: bool
    final: str


def luhn_valido(numero):
    soma, dobrar = 0, False
    for d in reversed(numero):
        n = int(d)
        if dobrar:
            n = n * 2 - 9 if n * 2 > 9 else n * 2
        soma += n
        dobrar = not dobrar
    return soma % 10 == 0


class GatewaySimulado:
    def cobrar_cartao(self, cartao, valor, hoje=None):
        numero = "".join(ch for ch in str(cartao.get("numero", "")) if ch.isdigit())
        nome = (cartao.get("nome") or "").strip()
        validade = (cartao.get("validade") or "").strip()
        cvv = (cartao.get("cvv") or "").strip()

        if len(numero) < 13 or len(numero) > 19 or not luhn_valido(numero):
            raise RegraNegocioErro("Número de cartão inválido.")
        if not nome:
            raise RegraNegocioErro("Informe o nome impresso no cartão.")
        if not (cvv.isdigit() and len(cvv) in (3, 4)):
            raise RegraNegocioErro("CVV inválido.")
        try:
            mes, ano = validade.split("/")
            mes, ano = int(mes), 2000 + int(ano[-2:])
            if not 1 <= mes <= 12:
                raise ValueError
        except ValueError:
            raise RegraNegocioErro("Validade inválida. Use o formato MM/AA.")
        hoje = hoje or date.today()
        if (ano, mes) < (hoje.year, hoje.month):
            raise RegraNegocioErro("Cartão vencido.")
        if numero == CARTAO_RECUSADO:
            raise RegraNegocioErro("Pagamento recusado pela operadora. Tente outro cartão ou pague com PIX.")
        return ResultadoCobranca(aprovado=True, final=numero[-4:])

    def gerar_pix(self, valor):
        # Formato ilustrativo de "copia e cola" (não é um BR Code válido para bancos).
        return f"00020126SIMULADO-SWEETINDULGENCE-{secrets.token_hex(8).upper()}-VALOR{valor}"
