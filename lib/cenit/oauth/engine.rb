module Cenit
  module Oauth
    class Engine < ::Rails::Engine
      isolate_namespace Cenit::Oauth
    end
  end
end
