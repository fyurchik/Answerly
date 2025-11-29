require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI (protect in production with authentication)
  mount Sidekiq::Web => '/sidekiq'

  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Interview Sessions (protected by authentication in controller)
  resources :interview_sessions do
    resource :interview, only: [:show] do
      post :save_answer
      post :next_question
    end
    resource :feedback, only: [:show]
  end

  # HeyGen webhook
  post "/heygen/webhook", to: "heygen_webhooks#create"

  # Root path - Interview Sessions index
  root "interview_sessions#index"
end
