require "test_helper"

class Courier::DeliveriesTest < ActionDispatch::IntegrationTest
  setup do
    @order = place_order
    @order.advance_to!("preparing")
    @order.assign_courier!(users(:entregador))
    @order.advance_to!("out_for_delivery")
  end

  test "entregador cai nas entregas depois do login e vê o pedido com o GPS (US16)" do
    sign_in_as users(:entregador)
    assert_redirected_to courier_root_path
    follow_redirect!
    assert_select "a.card", /##{@order.code}.*Cliente Teste/m

    get courier_delivery_path(@order)
    assert_select "[data-teste=endereco-entrega]", /Entrega no endereço.*Rua A, 10/m
    assert_select "a[href^=?]", "https://www.google.com/maps/search/?api=1&query=Rua%20A", text: "🗺️ Abrir no GPS"
  end

  test "outro entregador não vê nem conclui a entrega" do
    sign_in_as users(:outro_entregador)

    get courier_delivery_path(@order)
    assert_response :not_found
    post courier_delivery_completion_path(@order), params: { confirmed: "1" }
    assert_response :not_found
    assert @order.reload.out_for_delivery?
  end

  test "cliente não entra na área do entregador" do
    sign_in_as users(:cliente)
    get courier_root_path

    assert_response :forbidden
  end

  test "ligar e WhatsApp ficam registrados (US18)" do
    sign_in_as users(:entregador)

    post courier_delivery_contact_path(@order), params: { channel: "call" }
    assert_redirected_to "tel:+5583999992222"
    post courier_delivery_contact_path(@order), params: { channel: "whatsapp" }
    assert_match %r{\Ahttps://wa.me/5583999992222\?text=Ol%C3%A1}, response.location

    assert_equal %w[call whatsapp], @order.contact_logs.order(:id).pluck(:channel)
  end

  test "marcar como entregue exige a confirmação com o cliente (US17)" do
    sign_in_as users(:entregador)

    post courier_delivery_completion_path(@order)
    assert_equal "Confirme com o cliente antes de marcar como entregue.", flash[:error]
    assert @order.reload.out_for_delivery?

    post courier_delivery_completion_path(@order), params: { confirmed: "1" }
    assert_redirected_to courier_deliveries_path
    assert @order.reload.delivered?
    assert_equal "Pedido ##{@order.code}: Entregue.", users(:cliente).notifications.recent_first.first.message
  end

  test "pedido atribuído e ainda em preparação aparece na lista, mas só abre depois de sair" do
    em_preparacao = place_order
    em_preparacao.advance_to!("preparing")
    em_preparacao.assign_courier!(users(:entregador))
    sign_in_as users(:entregador)

    get courier_deliveries_path
    assert_select "a.card", /##{@order.code}/
    assert_select "[data-teste=aguardando-sair]", /##{em_preparacao.code}.*Em preparação.*Saiu para entrega/m
    assert_select "a[href=?]", courier_delivery_path(em_preparacao), count: 0

    get courier_delivery_path(em_preparacao)
    assert_response :not_found
    post courier_delivery_completion_path(em_preparacao), params: { confirmed: "1" }
    assert em_preparacao.reload.preparing?
  end
end
