Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :reviews, only: [:index, :show, :create, :update, :destroy]
      resources :comments, only: [:index, :show, :create, :update, :destroy]
      get "health", to: "health#check"
    end
  end
end

