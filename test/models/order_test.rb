require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "calcula subtotal, desconto, frete e total e baixa o estoque (CU01)" do
    order = place_order(coupon_code: "BEMVINDO10")

    assert_equal BigDecimal("23.00"), order.subtotal
    assert_equal BigDecimal("2.30"), order.discount
    assert_equal BigDecimal("5.00"), order.shipping_fee
    assert_equal BigDecimal("25.70"), order.total
    assert order.paid?
    assert_equal "1111", order.card_last4
    assert_equal 18, cupcakes(:red_velvet).reload.stock
    assert_equal 1, coupons(:bemvindo).reload.uses_count
    assert_equal BigDecimal("11.50"), order.items.first.unit_price
  end

  test "não vende mais do que tem em estoque" do
    error = assert_raises(BusinessRuleError) { place_order(cart: { cupcakes(:caramelo).id => 5 }) }

    assert_equal "Só temos 4 unidade(s) de Caramelo Salgado.", error.message
  end

  test "pagamento recusado não grava o pedido nem mexe no estoque (CU01-B)" do
    assert_no_difference -> { Order.count } do
      assert_raises(BusinessRuleError) { place_order(card: DECLINED_CARD, coupon_code: "BEMVINDO10") }
    end
    assert_equal 20, cupcakes(:red_velvet).reload.stock
    assert_equal 0, coupons(:bemvindo).reload.uses_count
  end

  test "cupom expirado impede o pedido (CU01-A)" do
    assert_raises(BusinessRuleError) { place_order(coupon_code: "VERAO2025") }
  end

  test "entrega exige zona e endereço (US07)" do
    assert_equal "Escolha o bairro/zona de entrega.",
                 assert_raises(BusinessRuleError) { place_order(delivery_zone_id: nil) }.message
    assert_equal "Informe o endereço de entrega.",
                 assert_raises(BusinessRuleError) { place_order(address: " ") }.message
  end

  test "retirada na loja não cobra frete" do
    order = Order.place!(customer: users(:cliente), cart: { cupcakes(:red_velvet).id => 1 }, fulfillment: "pickup",
                         payment_method: "debit", card: APPROVED_CARD)

    assert_equal BigDecimal("0"), order.shipping_fee
    assert_equal BigDecimal("11.50"), order.total
    assert_equal %w[paid preparing ready_for_pickup delivered], order.timeline
  end

  test "carrinho vazio e opções inválidas" do
    assert_raises(BusinessRuleError) { place_order(cart: {}) }
    assert_raises(BusinessRuleError) { Order.place!(customer: users(:cliente), cart: { 1 => 1 }, fulfillment: "drone", payment_method: "pix") }
  end

  test "PIX aguarda o pagamento e depois confirma" do
    order = place_order(payment_method: "pix")

    assert order.awaiting_payment?
    assert_match "SIMULADO", order.pix_code
    order.confirm_pix!
    assert order.paid?
    assert_raises(BusinessRuleError) { order.confirm_pix! }
  end

  test "fluxo completo de entrega notifica cliente, admin e entregador (US09)" do
    order = place_order
    assert_equal [ "Pedido ##{order.code} confirmado! Pagamento aprovado." ], users(:cliente).notifications.pluck(:message)
    assert_match "Novo pedido ##{order.code}", users(:admin).notifications.last.message

    order.advance_to!("preparing")
    assert_raises(BusinessRuleError) { order.advance_to!("out_for_delivery") } # sem entregador
    order.assign_courier!(users(:entregador))
    order.advance_to!("out_for_delivery")
    order.advance_to!("delivered", by: users(:entregador))

    assert order.reload.delivered?
    assert_equal "Você recebeu o pedido ##{order.code} para entregar.", users(:entregador).notifications.last.message
    assert_equal 4, users(:cliente).notifications.count
  end

  test "cliente que desativou as notificações não recebe avisos" do
    users(:cliente).update!(notifications_enabled: false)
    place_order.advance_to!("preparing")

    assert_empty users(:cliente).notifications
  end

  test "transição inválida é recusada" do
    error = assert_raises(BusinessRuleError) { place_order.advance_to!("delivered") }

    assert_equal "Não é possível passar de “Pagamento aprovado” para “Entregue”.", error.message
  end

  test "cancelar devolve o estoque (US12 RN#2)" do
    order = place_order
    order.advance_to!("canceled")

    assert_equal 20, cupcakes(:red_velvet).reload.stock
  end

  test "entregador tem no máximo 3 entregas em andamento (US14)" do
    3.times { place_order(cart: { cupcakes(:morango).id => 1 }).assign_courier!(users(:entregador)) }
    error = assert_raises(BusinessRuleError) { place_order.assign_courier!(users(:entregador)) }

    assert_match "já tem 3 entregas em andamento", error.message
  end

  test "outro entregador não conclui a entrega" do
    order = place_order
    order.advance_to!("preparing")
    order.assign_courier!(users(:entregador))
    order.advance_to!("out_for_delivery")

    assert_raises(BusinessRuleError) { order.advance_to!("delivered", by: users(:outro_entregador)) }
  end

  test "relatório conta só pedidos entregues (US15)" do
    delivered = place_order
    delivered.update!(status: "delivered")
    place_order(cart: { cupcakes(:morango).id => 1 })

    report = Order.sales_report(Time.zone.today, Time.zone.today)

    assert_equal 1, report[:orders_count]
    assert_equal BigDecimal("28.00"), report[:total]
    assert_equal [ [ "Red Velvet", 2, BigDecimal("23.00") ] ], report[:best_sellers]
  end

  test "relatório usa o dia no horário de Brasília" do
    order = place_order
    order.update!(status: "delivered", created_at: Time.utc(2026, 11, 17, 1, 30)) # 22h30 de 16/11 em Brasília

    assert_equal 1, Order.sales_report(Date.new(2026, 11, 16), Date.new(2026, 11, 16))[:orders_count]
    assert_equal 0, Order.sales_report(Date.new(2026, 11, 17), Date.new(2026, 11, 17))[:orders_count]
  end
end
