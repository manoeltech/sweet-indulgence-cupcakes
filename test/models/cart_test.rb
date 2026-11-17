require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup { @cart = Cart.new({}) }

  test "soma quantidades e calcula o subtotal" do
    @cart.add(cupcakes(:red_velvet), 2)
    @cart.add(cupcakes(:morango))

    assert_equal 3, @cart.count
    assert_equal BigDecimal("33.50"), @cart.subtotal
  end

  test "não deixa passar do estoque (US04 RNF#1)" do
    @cart.add(cupcakes(:caramelo), 4)
    error = assert_raises(BusinessRuleError) { @cart.change(cupcakes(:caramelo), 1) }

    assert_equal "Só temos 4 unidade(s) de Caramelo Salgado em estoque.", error.message
    assert_equal 4, @cart.count
  end

  test "diminuir até zero remove o item" do
    @cart.add(cupcakes(:red_velvet))
    @cart.change(cupcakes(:red_velvet), -1)

    assert @cart.empty?
  end

  test "cupom aplicado dá desconto e cupom que expirou depois aparece como erro" do
    @cart.add(cupcakes(:red_velvet), 2)
    @cart.apply_coupon("bemvindo10")
    assert_equal BigDecimal("20.70"), @cart.total

    coupons(:bemvindo).update!(valid_until: Date.yesterday)
    cart = Cart.new({ "cart" => @cart.items.transform_keys(&:to_s), "coupon_code" => "BEMVINDO10" })
    assert_equal "Este cupom expirou.", cart.coupon_error
    assert_equal BigDecimal("23.00"), cart.total
  end

  test "item que saiu do cardápio some do carrinho" do
    @cart.add(cupcakes(:red_velvet))
    cupcakes(:red_velvet).update!(active: false)

    assert Cart.new({ "cart" => { cupcakes(:red_velvet).id.to_s => 1 } }).empty?
  end
end
