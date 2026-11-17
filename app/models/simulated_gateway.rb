# Gateway de pagamento SIMULADO.
#
# O US08 pede um gateway certificado (PCI-DSS). Integrar um gateway real exige conta
# comercial e chaves de produção, então nesta entrega o pagamento é simulado com as mesmas
# regras de um gateway de testes. Trocar por um gateway real só muda esta classe.
#
# Cartões de teste:
#   4111 1111 1111 1111 -> aprovado
#   4000 0000 0000 0002 -> recusado (exercita o fluxo alternativo CU01-B)
class SimulatedGateway
  DECLINED_CARD = "4000000000000002".freeze

  # Devolve os 4 últimos dígitos do cartão aprovado ou levanta BusinessRuleError.
  def charge_card!(card, _amount, today: Time.zone.today)
    number = card[:number].to_s.gsub(/\D/, "")
    name = card[:name].to_s.strip
    expiry = card[:expiry].to_s.strip
    cvv = card[:cvv].to_s.strip

    raise BusinessRuleError, "Número de cartão inválido." unless number.length.between?(13, 19) && luhn_valid?(number)
    raise BusinessRuleError, "Informe o nome impresso no cartão." if name.empty?
    raise BusinessRuleError, "CVV inválido." unless cvv.match?(/\A\d{3,4}\z/)

    month, year = parse_expiry(expiry)
    raise BusinessRuleError, "Cartão vencido." if Date.new(year, month).end_of_month < today
    raise BusinessRuleError, "Pagamento recusado pela operadora. Tente outro cartão ou pague com PIX." if number == DECLINED_CARD

    number.last(4)
  end

  # Formato ilustrativo de "copia e cola" (não é um BR Code válido para bancos).
  def pix_code(amount)
    "00020126SIMULADO-SWEETINDULGENCE-#{SecureRandom.hex(8).upcase}-VALOR#{format('%.2f', amount)}"
  end

  private

  def luhn_valid?(number)
    sum = number.reverse.chars.each_with_index.sum do |digit, index|
      value = digit.to_i
      value *= 2 if index.odd?
      value > 9 ? value - 9 : value
    end
    (sum % 10).zero?
  end

  def parse_expiry(expiry)
    match = expiry.match(%r{\A(\d{1,2})/(\d{2}|\d{4})\z})
    month = match && match[1].to_i
    raise BusinessRuleError, "Validade inválida. Use o formato MM/AA." unless month&.between?(1, 12)

    [ month, 2000 + match[2].last(2).to_i ]
  end
end
