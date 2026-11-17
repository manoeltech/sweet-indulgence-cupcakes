require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "cadastro cria a conta de cliente e já entra" do
    post registration_path, params: { user: { name: "Ana Souza", email: "Ana@Teste.com", phone: "83988887777",
                                               password: "segredo1", password_confirmation: "segredo1" } }

    assert_redirected_to root_path
    assert User.find_by(email: "ana@teste.com").customer?
    follow_redirect!
    assert_select ".msg-sucesso", "Bem-vindo(a), Ana!"
  end

  test "cadastro inválido mostra os erros e não cria a conta" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { name: "", email: "cliente@teste.com", password: "123", password_confirmation: "321" } }
    end

    assert_response :unprocessable_entity
    assert_select ".msg-erro", /Informe seu nome.*Já existe uma conta com este e-mail/
  end

  test "formulário de login mantém a largura máxima (estilo dentro de html:)" do
    get new_session_path

    assert_select "form.card[style*='max-width:420px']"
  end

  test "login com senha errada" do
    post session_path, params: { email: "cliente@teste.com", password: "errada" }

    assert_response :unauthorized
    assert_select ".msg-erro", "E-mail ou senha incorretos."
  end

  test "login volta para a página pedida, mas só para caminhos internos" do
    post session_path(return_to: "/perfil"), params: { email: "cliente@teste.com", password: "cupcake123" }
    assert_redirected_to "/perfil"

    delete logout_path
    post session_path(return_to: "//site-malicioso.com"), params: { email: "cliente@teste.com", password: "cupcake123" }
    assert_redirected_to root_path
  end

  test "perfil exige login" do
    get profile_path

    assert_redirected_to new_session_path(return_to: "/perfil")
  end

  test "cliente salva endereço e desativa as notificações" do
    sign_in_as users(:cliente)

    post profile_addresses_path, params: { address: { street: "Rua das Flores", number: "45", district: "Centro", zip_code: "58770-000" } }
    assert_redirected_to profile_path
    assert_equal "Rua das Flores, 45 – Centro, CEP 58770-000", users(:cliente).addresses.first.to_s

    post profile_addresses_path, params: { address: { street: "", number: "", district: "", zip_code: "" } }
    assert_equal "Preencha todos os campos do endereço.", flash[:error]

    patch profile_notification_preference_path, params: { enabled: "0" }
    assert_not users(:cliente).reload.notifications_enabled?
  end

  test "abrir as notificações marca como lidas" do
    Notification.create!(user: users(:cliente), message: "Pedido #ABC123: Em preparação.")
    sign_in_as users(:cliente)

    get root_path
    assert_select ".contador", "1"
    get notifications_path
    assert_select ".card", /Pedido #ABC123/
    assert_equal 0, users(:cliente).unread_notifications_count
  end

  test "sair encerra a sessão" do
    sign_in_as users(:cliente)
    delete logout_path
    get profile_path

    assert_response :redirect
  end

  test "login e cadastro marcam os campos obrigatórios" do
    get new_session_path
    assert_select "label[for=email] abbr.obrigatorio", "*"
    assert_select "label[for=password] abbr.obrigatorio", "*"

    get new_registration_path
    assert_select "abbr.obrigatorio", 5 # legenda + nome, e-mail, senha e confirmação
    assert_select "label[for=user_phone] abbr", count: 0
  end
end
