Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Vitrine (US01, US02, US03)
  root "cupcakes#index"
  resources :cupcakes, only: :show, path: "cupcake" do
    resource :image, only: :show, module: :cupcakes, path: "imagem"
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
