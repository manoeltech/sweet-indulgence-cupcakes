Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Vitrine (US01, US02, US03)
  root "cupcakes#index"
  resources :cupcakes, only: :show, path: "cupcake" do
    resource :image, only: :show, module: :cupcakes, path: "imagem"
    resource :favorite, only: :create, module: :cupcakes, path: "favorito"
  end
  resources :favorites, only: :index, path: "favoritos" # US05

  # Carrinho (US04) e cupom (US06)
  resource :cart, only: :show, path: "carrinho" do
    scope module: :carts do
      resources :items, only: %i[create update destroy], path: "itens"
      resource :coupon, only: %i[create destroy], path: "cupom"
    end
  end

  # Checkout (CU01: US07 entrega/retirada, US08 pagamento)
  resource :checkout, only: %i[new create], path: "finalizar", path_names: { new: "pedido" }
  resources :orders, only: %i[index show], path: "pedidos" do # acompanhamento (US09)
    scope module: :orders do
      resource :confirmation, only: :show, path: "confirmacao"
      resource :pix_payment, only: :create, path: "pix"
      resources :reviews, only: :create, path: "avaliacoes" # US10
    end
  end

  # Conta do usuário
  get "entrar" => "sessions#new", as: :new_session
  post "entrar" => "sessions#create", as: :session
  delete "sair" => "sessions#destroy", as: :logout
  get "cadastro" => "registrations#new", as: :new_registration
  post "cadastro" => "registrations#create", as: :registration
  resource :profile, only: :show, path: "perfil" do
    scope module: :profiles do
      resources :addresses, only: :create, path: "enderecos"
      resource :notification_preference, only: :update, path: "notificacoes"
    end
  end
  resources :notifications, only: :index, path: "notificacoes"
end
