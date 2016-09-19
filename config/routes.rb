Cenit::Oauth::Engine.routes.draw do

  post 'token', to: 'token_end_point#index'
end
