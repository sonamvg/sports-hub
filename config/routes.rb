Rails.application.routes.draw do
  root "home#index"
  get "favicon.ico", to: redirect("/favicon.svg")
  get "terms", to: "home#terms"

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
    resources :academy_membership_requests, only: [] do
      member do
        patch :approve
        patch :reject
        patch :dismiss
      end
    end

    member do
      get :athletes
      get :notifications
      patch :approve
      patch :reject
    end
  end

  resources :tournaments, only: %i[index show new create edit update destroy] do
    member do
      get :venue_setup
      patch :venue_setup, action: :update_venue_setup
    end
    resources :tournament_categories, path: "categories", only: %i[index show]
    resources :tournament_organizer_invitations, path: "organizer-invitations", only: %i[create]
    resources :tournament_referees, path: "referees"
    resources :registrations, only: %i[index new create]
  end

  namespace :super_admin do
    resources :athletes, only: %i[index destroy]
    resources :notifications, only: %i[index] do
      member do
        patch :approve
        patch :reject
        patch :dismiss
      end
    end
  end

  namespace :organizer do
    resources :tournaments, only: [] do
      resources :weight_checks, only: %i[index]
      resources :tournament_categories, only: [] do
        resource :draw, only: %i[show create]
      end
    end
    resources :registrations, only: %i[index show] do
      member do
        patch :approve
        patch :reject
      end
      resources :weight_checks, only: %i[create]
    end
    resources :matches, only: %i[update]
  end
end
