require "test_helper"

class FavoritesTest < ActionDispatch::IntegrationTest
  test "cliente favorita pelo coração da vitrine e vê na lista (US05)" do
    sign_in_as users(:cliente)

    post cupcake_favorite_path(cupcakes(:red_velvet)), params: { return_to: "/?categoria=classicos" }
    assert_redirected_to "/?categoria=classicos"
    assert_equal "Red Velvet foi para os favoritos.", flash[:success]

    get favorites_path
    assert_select "[data-teste=produto]", 1
    assert_select "form.coracao button", "♥"

    post cupcake_favorite_path(cupcakes(:red_velvet))
    get favorites_path
    assert_select ".vazio", /ainda não favoritou/
  end

  test "visitante precisa entrar para favoritar" do
    post cupcake_favorite_path(cupcakes(:red_velvet))

    assert_redirected_to new_session_path # sem return_to: a URL do formulário só aceita POST
  end

  test "administrador não tem lista de favoritos" do
    sign_in_as users(:admin)
    get favorites_path

    assert_response :forbidden
    assert_select "h1", "Acesso negado"
  end
end
