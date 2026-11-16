Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Vitrine (US01, US02, US03)
  root "cupcakes#index"
  resources :cupcakes, only: :show, path: "cupcake" do
    resource :image, only: :show, module: :cupcakes, path: "imagem"
  end
end
