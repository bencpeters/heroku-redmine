Rails.application.routes.draw do
  match 'stuff_to_do/:action.:format', :to => 'stuff_to_do'
  resources :stuff_to_do
end
