Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "health", to: "health#check"

      post "auth/register", to: "authentication#register"
      post "auth/login", to: "authentication#login"
      post "auth/logout", to: "authentication#logout"

      resources :reviews, only: [:index, :show, :create, :update, :destroy]
      resources :comments, only: [:index, :show, :create, :update, :destroy]
    end
  end
end

