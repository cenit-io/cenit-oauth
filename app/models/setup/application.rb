module Setup
  class Application
    include Mongoid::Document
    include Cenit::MultiTenancy::Scoped
    include Cenit::Oauth::AppConfig
  end
end