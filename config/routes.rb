Rails.application.routes.draw do
  root "home#index"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  resources :users, only: %i[new create]
  resources :organizers, only: %i[index] do
    collection do
      get :profile
    end
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
      get :venue_setup
      patch :venue_setup, action: :update_venue_setup
      get :draw
      patch :set_draw
    end
    resources :tournament_categories, path: "categories", only: %i[index show new create edit update] do
      collection do
        post :create_defaults
      end
    end
    resources :tournament_organizer_invitations, path: "organizer-invitations", only: %i[create]
    resources :tournament_referees, path: "referees"
    resources :registrations, only: %i[index new create]
  end

  namespace :organizer do
    resources :tournaments, only: [] do
      resources :weight_checks, only: %i[index]
    end
    resources :registrations, only: %i[index show] do
      member do
        patch :approve
        patch :reject
      end
      resources :weight_checks, only: %i[create]
    end
  end
end
