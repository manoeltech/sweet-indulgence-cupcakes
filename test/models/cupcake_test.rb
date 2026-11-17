require "test_helper"

class CupcakeTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
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

  test "foto enviada é guardada com o tipo lido do próprio arquivo" do
    cupcake = cupcakes(:red_velvet)
    cupcake.update!(photo_upload: fixture_file_upload("cupcake.png", "application/octet-stream"))

    assert cupcake.uploaded_photo?
    assert_equal "image/png", cupcake.photo.content_type
    assert_equal file_fixture("cupcake.png").binread, cupcake.reload.photo.data
  end

  test "foto que não é imagem ou passa de 2 MB é recusada" do
    cupcake = cupcakes(:red_velvet)

    cupcake.photo_upload = fixture_file_upload("nao-e-imagem.txt", "image/png")
    assert_not cupcake.valid?
    assert_includes cupcake.errors[:photo_upload], "A foto precisa ser um arquivo JPG, PNG ou WebP."

    big = Rack::Test::UploadedFile.new(StringIO.new("\x89PNG\r\n\x1A\n".b + ("0" * CupcakePhoto::MAX_BYTES)), "image/png", original_filename: "grande.png")
    cupcake = cupcakes(:morango)
    cupcake.photo_upload = big
    assert_not cupcake.valid?
    assert_includes cupcake.errors[:photo_upload], "A foto precisa ter até 2 MB."
    assert_not cupcake.uploaded_photo?
  end
end
