require "test_helper"

class Admin::DashboardsTest < ActionDispatch::IntegrationTest
  setup { @order = place_order }

  test "cliente e visitante não entram na área do administrador" do
    get admin_root_path
    assert_redirected_to new_session_path(return_to: "/admin")

    sign_in_as users(:cliente)
    get admin_root_path
    assert_response :forbidden
  end

  test "admin cai no painel depois do login e vê pedidos ativos, vendas e estoque baixo (US13)" do
    sign_in_as users(:admin)
    assert_redirected_to admin_root_path
    follow_redirect!

    assert_select "[data-teste=pedido-#{@order.code}]"
    assert_select ".cards .card", /R\$ 28,00\s*Vendas de hoje/
    assert_select ".msg-aviso", /Estoque baixo: .*Caramelo Salgado \(4\)/
  end

  test "filtro por status" do
    sign_in_as users(:admin)
    get admin_root_path(status: "delivered")

    assert_select ".vazio", "Nenhum pedido neste filtro."
  end

  test "fluxo do admin: preparar, atribuir entregador e enviar (US13, US14)" do
    sign_in_as users(:admin)

    patch admin_order_status_path(@order), params: { status: "preparing" }
    assert_equal "Pedido ##{@order.code}: Em preparação.", flash[:success]

    patch admin_order_status_path(@order), params: { status: "out_for_delivery" }
    assert_equal "Atribua um entregador antes de enviar o pedido.", flash[:error]

    patch admin_order_courier_path(@order), params: { courier_id: users(:entregador).id }
    patch admin_order_status_path(@order), params: { status: "out_for_delivery" }
    assert @order.reload.out_for_delivery?
    assert_equal users(:entregador), @order.courier
  end

  test "cancelar pelo painel devolve o estoque" do
    sign_in_as users(:admin)
    patch admin_order_status_path(@order), params: { status: "canceled" }

    assert @order.reload.canceled?
    assert_equal 20, cupcakes(:red_velvet).reload.stock
  end

  test "não atribui um cliente como entregador" do
    sign_in_as users(:admin)
    patch admin_order_courier_path(@order), params: { courier_id: users(:cliente).id }

    assert_equal "Escolha um entregador válido.", flash[:error]
  end
end
