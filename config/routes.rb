Rails.application.routes.draw do
  # Devise routes
  devise_for :users, controllers: {
    registrations: "users/registrations",
    invitations: "users/invitations"
  }

  # Document storage routes
  resources :folders do
    member do
      get :confirm_delete
      patch :restore
    end
  end

  resources :documents, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    collection do
      get :archive
    end
    member do
      get :download
      get :preview
      get :versions
    end
    resources :signature_requests, only: [:new, :create, :edit, :update] do
      member do
        patch :autosave
        delete :discard_draft
        post :cancel
        post :resend
        post :void
      end
    end
    resources :signature_templates, only: [:index, :create, :destroy] do
      member do
        post :apply
      end
    end
  end

  # Public signature routes (no auth)
  resources :signatures, only: [:show], param: :signature_token, controller: "public_signatures" do
    member do
      post :sign
      post :decline
      post :capture_artifact
      post :complete_field
      post :reset_field
      post :finalize
      get :success
    end
  end

  # Public document share routes (no auth)
  resources :shared_documents, only: [:show], param: :share_token, path: "shared" do
    member do
      get :download
    end
  end

  # Landing page (public)
  get "launch", to: "pages#launch"
  root "pages#home"
  get "contact", to: "pages#contact", as: :contact_us
  post "contact", to: "pages#submit_contact", as: :submit_contact

  # Authenticated dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard
  get "profile", to: "users#profile_redirect", as: :my_profile

  # Billing & Subscriptions
  get "billing", to: "subscriptions#billing"
  get "subscribe/:plan", to: "subscriptions#checkout", as: :subscribe
  post "billing/portal", to: "subscriptions#portal", as: :billing_portal
  post "stripe/webhooks", to: "stripe_webhooks#create"

  # Contacts
  resources :contacts do
    collection do
      get :search
    end
    member do
      patch :assign
      post :tag
      delete :untag
    end
    resources :contact_notes, only: [:create, :edit, :update, :destroy] do
      member do
        patch :complete_follow_up
      end
    end
  end

  # Tags (admin only)
  resources :tags, only: [:index, :create, :destroy]

  # Users
  resources :users, only: [:show, :edit, :update, :index] do
    member do
      get :profile
    end
  end

  # Admin
  namespace :admin do
    resources :users do
      member do
        patch :update_role
        patch :restore
        get :confirm_delete
        post :process_deletion
      end
    end
    resources :invitations, only: [:new, :create] do
      member do
        post :resend
      end
    end
  end

  # Search
  get "search", to: "search#index"
  get "search/suggestions", to: "search#suggestions"

  # API
  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "sync/status", to: "sync#status"
      resources :documents, only: [:show, :create, :update, :destroy] do
        get :download, on: :member
      end
      resources :folders, only: [:index, :show, :create]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
