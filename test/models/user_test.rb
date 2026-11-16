require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "senha precisa ter pelo menos 6 caracteres" do
    user = User.new(name: "Ana", email: "ana@teste.com", password: "123")

    assert_not user.valid?
    assert_includes user.errors[:password], "A senha precisa ter pelo menos 6 caracteres."
  end

  test "e-mail é normalizado e único" do
    user = User.new(name: "Ana", email: " CLIENTE@Teste.com ", password: "segredo1")

    assert_equal "cliente@teste.com", user.email
    assert_not user.valid?
    assert_includes user.errors[:email], "Já existe uma conta com este e-mail."
  end

  test "senha guardada só como hash" do
    user = User.create!(name: "Ana", email: "ana@teste.com", password: "segredo1")

    assert_not_equal "segredo1", user.password_digest
    assert user.authenticate("segredo1")
    assert_not user.authenticate("errada")
  end

  test "favoritar e desfavoritar (US05)" do
    assert Favorite.toggle!(users(:cliente), cupcakes(:red_velvet))
    assert users(:cliente).reload.favorited?(cupcakes(:red_velvet))
    assert_not Favorite.toggle!(users(:cliente), cupcakes(:red_velvet))
  end
end
