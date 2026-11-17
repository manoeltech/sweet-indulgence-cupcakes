require "test_helper"

class Admin::CupcakesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  def valid_params(**changes)
    { cupcake: { name: "Pistache", category_id: categories(:classicos).id, description: "Creme de pistache.",
                 price: "13,90", stock: "12", min_stock: "5", allergens: "Glúten, Oleaginosas", color: "#84cc16" }.merge(changes) }
  end

  test "cadastra cupcake com preço digitado com vírgula e ele aparece na vitrine (US11)" do
    post admin_cupcakes_path, params: valid_params
    assert_redirected_to admin_cupcakes_path

    cupcake = Cupcake.find_by!(name: "Pistache")
    assert_equal BigDecimal("13.90"), cupcake.price
    get root_path
    assert_select ".produto .info a", text: "Pistache"
  end

  test "dados inválidos mostram os erros e mantêm o que foi digitado (CU02-A)" do
    assert_no_difference -> { Cupcake.count } do
      post admin_cupcakes_path, params: valid_params(name: "", price: "0", stock: "-3", category_id: "")
    end

    assert_response :unprocessable_entity
    assert_select ".msg-erro", "Informe o nome do cupcake."
    assert_select ".msg-erro", "O preço precisa ser maior que zero."
    assert_select ".msg-erro", "O estoque não pode ser negativo."
    assert_select ".msg-erro", "Escolha uma categoria."
    assert_select ".msg-erro", text: "é obrigatório(a)", count: 0
    assert_select "textarea[name='cupcake[description]']", "Creme de pistache."
  end

  test "edita o preço sem mudar o preço dos pedidos já feitos" do
    order = place_order
    patch admin_cupcake_path(cupcakes(:red_velvet)), params: { cupcake: { price: "12,00" } }

    assert_equal BigDecimal("12.00"), cupcakes(:red_velvet).reload.price
    assert_equal BigDecimal("11.50"), order.items.first.unit_price
  end

  test "remoção exige o nome exato e só tira do cardápio (CU02 passo 5 e CU02-B)" do
    cupcake = cupcakes(:red_velvet)

    delete admin_cupcake_path(cupcake), params: { confirmation: "red" }
    assert_equal "Remoção cancelada: digite o nome exato do cupcake para confirmar.", flash[:warning]
    assert cupcake.reload.active?

    delete admin_cupcake_path(cupcake), params: { confirmation: "Red Velvet" }
    assert_not cupcake.reload.active?
    get root_path
    assert_select ".produto .info a", text: "Red Velvet", count: 0
  end

  test "reposição de estoque (US12)" do
    patch admin_cupcake_stock_path(cupcakes(:caramelo)), params: { stock: "30" }
    assert_equal 30, cupcakes(:caramelo).reload.stock

    patch admin_cupcake_stock_path(cupcakes(:caramelo)), params: { stock: "-1" }
    assert_equal "Informe um estoque inteiro igual ou maior que zero.", flash[:error]
    assert_equal 30, cupcakes(:caramelo).reload.stock
  end

  test "cadastra cupcake com foto e a vitrine mostra a foto enviada" do
    post admin_cupcakes_path, params: valid_params(photo_upload: fixture_file_upload("cupcake.png", "image/png"))
    assert_redirected_to admin_cupcakes_path

    cupcake = Cupcake.find_by!(name: "Pistache")
    get root_path
    assert_select "img[alt='Pistache'][src=?]", cupcake_photo_path(cupcake, v: cupcake.photo_updated_at.to_i)

    get cupcake_photo_path(cupcake)
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal file_fixture("cupcake.png").binread, response.body.b
  end

  test "arquivo que não é imagem volta com o erro e não cria o cupcake" do
    assert_no_difference -> { Cupcake.count } do
      post admin_cupcakes_path, params: valid_params(photo_upload: fixture_file_upload("nao-e-imagem.txt", "image/png"))
    end

    assert_response :unprocessable_entity
    assert_select ".msg-erro", "A foto precisa ser um arquivo JPG, PNG ou WebP."
  end

  test "editar sem enviar foto mantém a foto atual" do
    cupcake = cupcakes(:red_velvet)
    cupcake.update!(photo_upload: fixture_file_upload("cupcake.png", "image/png"))

    patch admin_cupcake_path(cupcake), params: { cupcake: { name: "Red Velvet Especial" } }
    assert_redirected_to admin_cupcakes_path
    assert cupcake.reload.uploaded_photo?
    assert_equal "Red Velvet Especial", cupcake.name
  end

  test "formulário marca os campos obrigatórios" do
    get new_admin_cupcake_path

    assert_select ".legenda-obrigatorio", /Campos obrigatórios/
    %w[name category_id description price stock min_stock].each do |field|
      assert_select "label[for=cupcake_#{field}] abbr.obrigatorio[title=obrigatório]", "*"
      assert_select "[name='cupcake[#{field}]'][required]"
    end
    assert_select "label[for=cupcake_ingredients] abbr", count: 0
    assert_select "input[type=file][name='cupcake[photo_upload]'][accept='image/jpeg,image/png,image/webp']"
  end
end
