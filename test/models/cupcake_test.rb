require "test_helper"

class CupcakeTest < ActiveSupport::TestCase
  test "vitrine esconde cupcakes sem estoque e fora do cardápio (US01)" do
    names = Cupcake.storefront.map(&:name)

    assert_includes names, "Red Velvet"
    assert_not_includes names, "Baunilha Esgotada"
    assert_not_includes names, "Limão Antigo"
  end

  test "vitrine filtra por categoria e busca pelo nome (US02)" do
    assert_equal [ "Morango com Chantilly" ], Cupcake.storefront(category_slug: "frutas").map(&:name)
    assert_equal [ "Red Velvet" ], Cupcake.storefront(query: "velv").map(&:name)
    assert_empty Cupcake.storefront(category_slug: "frutas", query: "velvet")
  end

  test "cupcake inválido lista os erros em português" do
    cupcake = Cupcake.new(price: 0, stock: -1)

    assert_not cupcake.valid?
    assert_includes cupcake.errors[:name], "Informe o nome do cupcake."
    assert_includes cupcake.errors[:price], "O preço precisa ser maior que zero."
    assert_includes cupcake.errors[:stock], "O estoque não pode ser negativo."
  end

  test "estoque baixo aparece para o administrador (US12)" do
    assert_equal [ "Caramelo Salgado" ], Cupcake.low_stock.map(&:name) - [ "Baunilha Esgotada" ]
  end

  test "estoque nunca fica negativo" do
    error = assert_raises(BusinessRuleError) { cupcakes(:caramelo).adjust_stock!(-5) }

    assert_equal "Estoque insuficiente de Caramelo Salgado.", error.message
    assert_equal 4, cupcakes(:caramelo).reload.stock
  end

  test "remover do cardápio exige o nome exato e mantém o registro (CU02)" do
    cupcake = cupcakes(:red_velvet)

    assert_raises(BusinessRuleError) { cupcake.remove_from_menu!("red velvet") }
    assert cupcake.reload.active?

    cupcake.remove_from_menu!("Red Velvet")
    assert_not cupcake.reload.active?
  end

  test "alérgenos viram uma lista" do
    assert_equal [ "Glúten", "Lactose", "Ovo" ], cupcakes(:red_velvet).allergen_list
  end
end
