Rails.application.routes.draw do
  root 'dashboard#index'
  devise_for :users, skip: [:registrations]

  post '/messages/reply', to: 'messages#reply'
end