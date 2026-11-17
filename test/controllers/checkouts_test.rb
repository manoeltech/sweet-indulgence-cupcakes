require "test_helper"

class CheckoutsTest < ActionDispatch::IntegrationTest
  setup do
    post cart_items_path, params: { cupcake_id: cupcakes(:red_velvet).id, quantity: 2 }
  end

  def checkout_params(**changes)
    { checkout: { fulfillment: "delivery", payment_method: "credit", delivery_zone_id: delivery_zones(:centro).id,
                  address: "Rua das Flores, 45 – Centro", card: APPROVED_CARD }.merge(changes) }
  end

  test "checkout exige login e volta para ele depois" do
    get new_checkout_path
    assert_redirected_to new_session_path(return_to: new_checkout_path)

    post session_path(return_to: new_checkout_path), params: { email: "cliente@teste.com", password: "cupcake123" }
    assert_redirected_to new_checkout_path
  end

  test "compra completa com cupom aplicado antes do login (CU01)" do
    post cart_coupon_path, params: { code: "BEMVINDO10" }
    sign_in_as users(:cliente)

    get new_checkout_path
    assert_select "td", text: "Cupom BEMVINDO10"
    post checkout_path, params: checkout_params

    order = users(:cliente).orders.last
    assert_redirected_to order_confirmation_path(order)
    assert_equal BigDecimal("25.70"), order.total
    follow_redirect!
    assert_select "h1", "Pedido ##{order.code} confirmado!"
    assert_select "p", /cartão final 1111/
    get cart_path
    assert_select ".vazio", /carrinho está vazio/
  end

  test "cartão recusado volta ao checkout com a mensagem e mantém o carrinho (CU01-B)" do
    sign_in_as users(:cliente)

    assert_no_difference -> { Order.count } do
      post checkout_path, params: checkout_params(card: DECLINED_CARD)
    end
    assert_response :unprocessable_entity
    assert_select ".msg-erro", /Pagamento recusado pela operadora/
    assert_select "input[name='checkout[address]'][value='Rua das Flores, 45 – Centro']"
    assert_equal 2, Cart.new(session).count
  end

  test "entrega com endereço salvo" do
    users(:cliente).addresses.create!(street: "Rua B", number: "7", district: "Centro", zip_code: "58770-000")
    sign_in_as users(:cliente)

    post checkout_path, params: checkout_params(address: "", saved_address_id: users(:cliente).addresses.first.id)

    assert_equal "Rua B, 7 – Centro, CEP 58770-000", users(:cliente).orders.last.delivery_address
  end

  test "PIX mostra o código e o botão simula a confirmação do banco" do
    sign_in_as users(:cliente)
    post checkout_path, params: checkout_params(payment_method: "pix", fulfillment: "pickup")
    order = users(:cliente).orders.last
    follow_redirect!

    assert_select "h1", /aguardando o PIX/
    assert_select "#pix", /SIMULADO/
    post order_pix_payment_path(order)
    assert order.reload.paid?
  end

  test "cliente não vê a confirmação de pedido de outra pessoa" do
    order = place_order(customer: users(:outro_cliente))
    sign_in_as users(:cliente)

    get order_confirmation_path(order)
    assert_response :not_found
  end

  test "carrinho vazio não abre o checkout" do
    sign_in_as users(:cliente)
    delete cart_item_path(cupcakes(:red_velvet))

    get new_checkout_path
    assert_redirected_to root_path
  end
end
