require "test_helper"

class CouponTest < ActiveSupport::TestCase
  test "cupom válido calcula o desconto, sem diferenciar maiúsculas" do
    coupon = Coupon.find_valid!(" bemvindo10 ")

    assert_equal BigDecimal("2.30"), coupon.discount_on(BigDecimal("23.00"))
  end

  test "código em branco significa sem cupom" do
    assert_nil Coupon.find_valid!("")
  end

  test "mensagens para cupom inexistente, expirado e esgotado (US06 CA#3)" do
    assert_equal "Cupom inválido.", assert_raises(BusinessRuleError) { Coupon.find_valid!("NAOEXISTE") }.message
    assert_equal "Este cupom expirou.", assert_raises(BusinessRuleError) { Coupon.find_valid!("VERAO2025") }.message
    assert_equal "Este cupom atingiu o limite de usos.", assert_raises(BusinessRuleError) { Coupon.find_valid!("ULTIMO") }.message
  end

  test "desconto fora de 1 a 90% é recusado" do
    coupon = Coupon.new(code: "DEMAIS", percentage: 95, valid_until: Date.tomorrow)

    assert_not coupon.valid?
    assert_includes coupon.errors[:percentage], "O desconto precisa ser de 1 a 90%."
  end
end
