Rails.application.routes.draw do
  root "dashboard#show"

  # Authentication & Setup
  get "setup", to: "setup#new"
  post "setup", to: "setup#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  patch "locale", to: "locales#update"

  resources :users, except: [:show]

  resources :people do
    resources :comments, only: [:create]
    resource :tree, only: :show, controller: "tree"
    resource :fan_chart, only: :show, controller: "fan_chart"
    resource :report, only: :show, controller: "reports"
    resources :relationships, only: [:new, :create, :destroy]
  end

  resources :comments, only: [:destroy]

  resources :families, only: [:show, :create, :destroy]
  resources :search, only: :index

  # Relationship calculator
  get "relationship_calculator", to: "relationship_calculator#index"
  get "relationship_calculator/result", to: "relationship_calculator#result"

  # Map view
  get "map", to: "map#index"
  get "map/data", to: "map#data"

  # Tree Health & Anomalies
  get "health", to: "health#index"

  resource :gedcom, only: [:new, :create], controller: "gedcom" do
    get :export, on: :member
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
