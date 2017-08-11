Rails.application.routes.draw do
  root 'invitee_groups#index'
  devise_for :users, skip: [:registrations]

  resources :invitee_groups do
    collection do
      get :group_form
      get :invitee_form
    end
  end

  post '/messages/reply', to: 'messages#reply'
end