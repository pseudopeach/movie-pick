Noar::Application.routes.draw do
  

  root 'picks#new'
  get "logout", to:"users#logout", as:"logout"
  
  resources :users

  resources :picks
end
