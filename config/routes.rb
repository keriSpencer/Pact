Rails.application.routes.draw do
  # Devise routes - registration disabled, invitations enabled
  devise_for :users, skip: [:registrations], controllers: {
    invitations: "users/invitations"
  }

  # Allow users to edit their own profile (without registration)
  devise_scope :user do
    get "users/edit" => "devise/registrations#edit", as: :edit_user_registration
    put "users" => "devise/registrations#update", as: :user_registration
  end

  # Document storage routes
  resources :folders do
    member do
      get :confirm_delete
      patch :restore
    end
  end

  resources :documents, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
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
    end
  end

  # Public document share routes (no auth)
  resources :shared_documents, only: [:show], param: :share_token, path: "shared" do
    member do
      get :download
    end
  end

  # Root route
  root "dashboard#index"

  # Contacts
  resources :contacts do
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

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
