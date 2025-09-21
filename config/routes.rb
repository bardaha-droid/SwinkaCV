Rails.application.routes.draw do
  namespace :api do
    resources :resumes, only: :create
    resources :cover_letters, only: :create do
      collection do
        post :export
      end
    end
  end

  root 'spa#index'
  get '*path', to: 'spa#index', constraints: ->(request) { !request.xhr? && request.format.html? }
end
