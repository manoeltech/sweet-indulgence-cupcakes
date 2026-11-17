require "test_helper"

class Admin::CouponsAndReportsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "cria cupom e ele passa a valer no carrinho (US06)" do
    post admin_coupons_path, params: { coupon: { code: "natal15", description: "Natal", percentage: "15", valid_until: 1.month.from_now.to_date, usage_limit: "" } }
    assert_redirected_to admin_coupons_path
    assert_equal "Cupom NATAL15 criado.", flash[:success]

    assert_equal 15, Coupon.find_valid!("NATAL15").percentage
  end

  test "cupom inválido ou repetido mostra o erro" do
    post admin_coupons_path, params: { coupon: { code: "BEMVINDO10", percentage: "95", valid_until: "" } }

    assert_response :unprocessable_entity
    assert_select ".msg-erro", /Já existe um cupom com esse código.*O desconto precisa ser de 1 a 90%.*Informe a validade./
  end

  test "lista mostra cupom expirado" do
    get admin_coupons_path
    assert_select "tr", /VERAO2025.*expirado/m
  end

  test "relatório mostra só pedidos entregues e as avaliações (US15)" do
    order = place_order
    order.update!(status: "delivered")
    Review.create!(user: users(:cliente), order: order, cupcake: cupcakes(:red_velvet), rating: 5, delivery_rating: 4, comment: "Ótimo!")
    place_order(cart: { cupcakes(:morango).id => 1 })

    get admin_report_path(period: "daily")
    assert_select ".cards .card", /R\$ 28,00\s*Total vendido/
    assert_select ".cards .card", /1\s*Pedidos concluídos/
    assert_select "td", "Red Velvet"
    assert_select ".card", /Ótimo!/
  end

  test "exporta o CSV para o Excel" do
    place_order.update!(status: "delivered")
    get admin_report_path(format: :csv, from: Time.zone.today, to: Time.zone.today)

    assert_equal "text/csv", response.media_type
    body = response.body.force_encoding("UTF-8")
    assert body.start_with?("﻿")
    assert_includes body, "Total vendido;28,00"
    assert_includes body, "Red Velvet;2;23,00"
  end

  test "datas inválidas não quebram a página" do
    get admin_report_path(from: "31/02/2026")

    assert_response :success
    assert_select ".msg-erro", "Datas inválidas."
  end
end
