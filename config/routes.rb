Rails.application.routes.draw do
  root "home#index"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  resources :users, only: %i[new create]
  resources :organizers, only: %i[index] do
    member do
      patch :approve
      patch :reject
    end
  end

  resources :athletes
  resources :academies do
    member do
      patch :approve
      patch :reject
    end
  end

  resources :tournaments, only: %i[index show new create edit update] do
    member do
      get :draw
    end
    resources :tournament_categories, path: "categories", only: %i[index show new create edit update]
    resources :registrations, only: %i[index new create]
  end

  namespace :organizer do
    resources :registrations, only: %i[index show] do
      member do
        patch :approve
        patch :reject
      end
    end
  end
end
