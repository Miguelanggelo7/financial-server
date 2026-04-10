Rails.application.routes.draw do
  devise_for :users,
    path: "api/v1/auth",
    path_names: {
      sign_in: "sign_in",
      sign_out: "sign_out",
      registration: "sign_up"
    },
    controllers: {
      sessions: "api/v1/sessions",
      registrations: "api/v1/registrations"
    },
    skip: [:passwords, :registrations]

  devise_scope :user do
    post "api/v1/auth/sign_up", to: "api/v1/registrations#create"
  end

  namespace :api do
    namespace :v1 do
      resources :categories, only: %i[index create destroy]
      resources :wallets do
        resources :transactions do
          collection do
            post :parse_from_prompt
          end
        end
      end

      scope :enablebanking do
        post :token, to: "enablebanking#create"
        get :aspsps, to: "enablebanking#list_available_aspsp"
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
