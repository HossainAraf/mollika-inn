Rails.application.routes.draw do
  # --- Public Guest-Facing ---
  root "home#index"

  resources :rooms, param: :slug, only: [ :index, :show ]

  resources :bookings, only: [ :new, :create, :show ] do
    collection do
      get  :check_availability   # AJAX: returns available rooms for date range
      post :hold                 # Turbo: hold a room for 15 min while guest fills form
    end
  end

  get  "/gallery",    to: "gallery#index"
  get  "/facilities", to: "facilities#index"
  get  "/contact",    to: "contacts#new"
  post "/contact",    to: "contacts#create"
  get  "/about",      to: "home#about"

  resources :reviews, only: [ :new, :create ]

  # --- Guest Portal (optional Phase 2) ---
  namespace :guests do
    resource :session, only: [ :new, :create, :destroy ]
    resource :profile, only: [ :show, :edit, :update ]
    resources :bookings, only: [ :index, :show ] do
      member { patch :cancel }
    end
  end

  # --- Admin Panel ---
  namespace :admin do
    get "dining_reservations/index"
    get "dining_reservations/show"
    get "menu_items/index"
    get "menu_items/new"
    get "menu_items/edit"
    get "menu_items/show"
    root "dashboard#index"

    resources :rooms do
      resources :availabilities, only: [ :index, :create, :destroy ]
    end
    resources :room_types do
      resources :rates
    end
    resources :bookings do
      member do
        patch :confirm
        patch :check_in
        patch :check_out
        patch :cancel
      end
    end
    resources :guests
    resources :gallery_albums do
      resources :gallery_images, only: [ :create, :destroy, :update ]
    end
    resources :facilities
    resources :reviews do
      member { patch :approve }
    end
    resources :menu_items
    resources :dining_reservations do
      member { patch :confirm; patch :cancel; patch :complete }
    end
    resources :contact_inquiries, only: [ :index, :show, :update, :destroy ]
    resource  :settings, only: [ :show, :update ]
    resources :reports, only: [ :index ] do
      collection do
        get :occupancy
        get :revenue
        get :bookings_export  # CSV download
      end
    end
  end

  # --- Auth (Rails 8 built-in) ---
  resource  :session,  only: [ :new, :create, :destroy ]
  resources :passwords, param: :token

  # --- Stripe Webhooks ---
  post "/webhooks/stripe", to: "webhooks/stripe#receive"
end
  # --- Stripe Webhooks ---
  post "/webhooks/stripe", to: "webhooks/stripe#receive"
end
