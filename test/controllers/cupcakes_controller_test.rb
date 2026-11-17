require "test_helper"

class CupcakesControllerTest < ActionDispatch::IntegrationTest
  test "vitrine lista os cupcakes disponíveis e as categorias (US01)" do
    get root_path

    assert_response :success
    assert_select "[data-teste=produto]", 3
    assert_select ".categorias a", text: /Frutas/
    assert_select ".selo", text: "Últimas 4 unidades"
  end

  test "filtro por categoria e busca (US02)" do
    get root_path(categoria: "frutas")
    assert_select "[data-teste=produto]", 1
    assert_select ".produto .info a", text: "Morango com Chantilly"

    get root_path(q: "nada parecido")
    assert_select ".vazio", text: /Nenhum cupcake encontrado para “nada parecido”/
  end

  test "detalhe mostra nutricional e alérgenos (US03)" do
    get cupcake_path(cupcakes(:red_velvet))

    assert_response :success
    assert_select "h1", "Red Velvet"
    assert_select ".tag", 3
    assert_select "td", text: "330 kcal"
    assert_select ".preco", text: "R$ 11,50"
  end

  test "cupcake fora do cardápio ou inexistente dá 404 com página amigável" do
    get cupcake_path(cupcakes(:fora_do_cardapio))
    assert_response :not_found
    assert_select "h1", "Página não encontrada"

    get cupcake_path(id: 999_999)
    assert_response :not_found
  end

  test "ilustração SVG usa a cor da cobertura" do
    get cupcake_image_path(cupcakes(:red_velvet), format: :svg)

    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_includes response.body, "#b91c1c"
  end

  test "sabor com foto real mostra a foto; cupcake sem foto mostra a ilustração" do
    sem_foto = cupcakes(:morango)
    sem_foto.update!(name: "Pistache da Casa")

    get root_path

    assert_select "img[alt='Red Velvet'][src*='cupcakes/red-velvet']"
    assert_select "img[alt='Pistache da Casa'][src='#{cupcake_image_path(sem_foto, format: :svg)}']"
  end
end
