require 'cenit/oauth/engine'
require 'cenit/oauth/app_config'
require 'cenit/oauth/user'

module Cenit
  module Oauth
    extend Cenit::Config

    class << self

      def custom_picture_url(&block)
        fail ArgumentError unless block.arity == 1
        @custom_picture_url_proc = block
      end

      def picture_url_for(user)
        @custom_picture_url_proc && @custom_picture_url_proc.call(user)
      end

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
