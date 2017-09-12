Rails.application.routes.draw do
  root 'invitee_groups#index'
  devise_for :users, skip: [:registrations]

  resources :invitee_groups do
    collection do
      get :group_form
      get :invitee_form
      post :send_pending_invites
    end
  end

  post '/invitees/receive_message', 'invitees#receive_message'

end