# frozen_string_literal: true

Rails.application.routes.draw do
  match '/admin' => redirect('/casein'), via: :get

  namespace :casein do
    resources :admin_users do
      member do
        patch :update_password
        patch :reset_password
      end
    end

    resource :admin_user_session, only: %i[new create destroy]
    resource :password_reset, only: %i[create edit update]

    match '/blank' => 'casein#blank', via: :get
    root to: 'casein#index'
  end
end
