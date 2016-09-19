require 'cenit/oauth/engine'
require 'cenit/oauth/app_config'

module Cenit
  module Oauth
    extend Cenit::Config

    class << self

      %w(app auth).each do |prefix|
        class_eval "def #{prefix}_model(*args)
        if (model = args[0]).is_a?(Class)
          options[:#{prefix}_model] = model
          #{prefix}_model_name model.to_s
        end
        options[:#{prefix}_model]
      end"
      end
    end
  end
end
