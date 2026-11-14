Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope "webhooks" do
    get  "whatsapp", to: "whatsapp_webhooks#verify"
    post "whatsapp", to: "whatsapp_webhooks#receive"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :admin do
    root "dashboard#index"   # /admin → later becomes the production report
  end

  # Defines the root path route ("/")
  root to: redirect("/session/new")   # visiting the app's root shows the login page
end
