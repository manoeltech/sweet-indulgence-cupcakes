require "test_helper"

class CartsTest < ActionDispatch::IntegrationTest
  test "adicionar, aumentar, diminuir e remover itens (US04)" do
    cupcake = cupcakes(:red_velvet)

    post cart_items_path, params: { cupcake_id: cupcake.id, quantity: 2 }
    assert_redirected_to cart_path
    follow_redirect!
    assert_select "[data-teste=item-carrinho]", 1
    assert_select "[data-teste=contador-carrinho]", "2"
    assert_select ".resumo .total", /R\$ 23,00/

    patch cart_item_path(cupcake), params: { step: "up" }
    patch cart_item_path(cupcake), params: { step: "down" }
    patch cart_item_path(cupcake), params: { step: "down" }
    get cart_path
    assert_select "[data-teste=contador-carrinho]", "1"

    delete cart_item_path(cupcake)
    follow_redirect!
    assert_select ".vazio", /Seu carrinho está vazio/
  end

  test "não adiciona mais do que o estoque" do
    post cart_items_path, params: { cupcake_id: cupcakes(:caramelo).id, quantity: 5 }, headers: { "HTTP_REFERER" => cupcake_url(cupcakes(:caramelo)) }

    assert_redirected_to cupcake_url(cupcakes(:caramelo))
    assert_equal "Só temos 4 unidade(s) de Caramelo Salgado em estoque.", flash[:error]
  end

  test "cupom inválido e expirado mostram a mensagem; válido dá desconto (US06)" do
    post cart_items_path, params: { cupcake_id: cupcakes(:red_velvet).id, quantity: 2 }

    post cart_coupon_path, params: { code: "VERAO2025" }
    assert_equal "Este cupom expirou.", flash[:error]

    post cart_coupon_path, params: { code: "bemvindo10" }
    follow_redirect!
    assert_select ".msg-sucesso", "Cupom BEMVINDO10 aplicado!"
    assert_select ".resumo .total", /R\$ 20,70/

    delete cart_coupon_path
    follow_redirect!
    assert_select ".resumo .total", /R\$ 23,00/
  end

  test "carrinho do visitante continua depois do login" do
    post cart_items_path, params: { cupcake_id: cupcakes(:morango).id }
    post cart_coupon_path, params: { code: "BEMVINDO10" }
    sign_in_as users(:cliente)

    get cart_path
    assert_select "[data-teste=item-carrinho]", 1
    assert_select ".status", /BEMVINDO10/
  end
end
