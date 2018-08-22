Rails.application.routes.draw do
  resources :status, only: [:index]

  namespace 'v1' do
    resources :status, only: [:index]
    resources :applications, only: [:create, :show]
  end
end
