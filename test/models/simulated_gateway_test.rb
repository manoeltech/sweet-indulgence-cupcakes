require "test_helper"

class SimulatedGatewayTest < ActiveSupport::TestCase
  setup { @gateway = SimulatedGateway.new }

  test "cartão de teste aprovado devolve só os 4 últimos dígitos" do
    assert_equal "1111", @gateway.charge_card!(APPROVED_CARD, 10)
  end

  test "cartão de teste recusado exercita o fluxo CU01-B" do
    error = assert_raises(BusinessRuleError) { @gateway.charge_card!(DECLINED_CARD, 10) }

    assert_match "recusado pela operadora", error.message
  end

  test "valida número (Luhn), nome, CVV e validade" do
    {
      { number: "4111 1111 1111 1112" } => "Número de cartão inválido.",
      { name: " " } => "Informe o nome impresso no cartão.",
      { cvv: "12" } => "CVV inválido.",
      { expiry: "13/30" } => "Validade inválida. Use o formato MM/AA.",
      { expiry: "01/20" } => "Cartão vencido."
    }.each do |change, message|
      error = assert_raises(BusinessRuleError) { @gateway.charge_card!(APPROVED_CARD.merge(change), 10) }
      assert_equal message, error.message
    end
  end

  test "PIX gera código copia e cola com o valor" do
    assert_match(/SIMULADO.*VALOR23\.00\z/, @gateway.pix_code(BigDecimal("23")))
  end
end
