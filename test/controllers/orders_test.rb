require "test_helper"

class OrdersTest < ActionDispatch::IntegrationTest
  setup do
    @order = place_order
    sign_in_as users(:cliente)
  end

  test "lista os pedidos do cliente e mostra a linha do tempo" do
    get orders_path
    assert_select "td", "##{@order.code}"
    assert_select ".status", "Pagamento aprovado"

    @order.advance_to!("preparing")
    get order_path(@order)
    assert_select ".timeline li.feito", 2
    assert_select ".resumo .total", /R\$ 28,00/
  end

  test "cliente vê quem está entregando" do
    @order.advance_to!("preparing")
    @order.assign_courier!(users(:entregador))
    @order.advance_to!("out_for_delivery")

    get order_path(@order)
    assert_select "p", /Carlos Entregador está a caminho/
  end

  test "cliente não vê pedido de outra pessoa" do
    other = place_order(customer: users(:outro_cliente))

    get order_path(other)
    assert_response :not_found
  end

  test "avaliação só aparece e só é aceita depois da entrega (US10)" do
    get order_path(@order)
    assert_select "form", text: /Enviar avaliação/, count: 0

    post order_reviews_path(@order), params: { review: { cupcake_id: cupcakes(:red_velvet).id, rating: 5, delivery_rating: 5 } }
    assert_equal "Você poderá avaliar depois que o pedido for entregue.", flash[:error]

    @order.update!(status: "delivered")
    post order_reviews_path(@order), params: { review: { cupcake_id: cupcakes(:red_velvet).id, rating: 5, delivery_rating: 4, comment: "Maravilhoso!" } }
    assert_equal "Obrigado pela avaliação!", flash[:success]
    follow_redirect!
    assert_select "p.card", /Red Velvet já avaliado/

    get cupcake_path(cupcakes(:red_velvet))
    assert_select ".card", /Maravilhoso!/
  end

  test "avaliação sem estrelas mostra a mensagem" do
    @order.update!(status: "delivered")
    post order_reviews_path(@order), params: { review: { cupcake_id: cupcakes(:red_velvet).id, comment: "sem nota" } }

    assert_equal "Dê uma nota de 1 a 5 estrelas para o cupcake e para a entrega.", flash[:error]
  end
end
