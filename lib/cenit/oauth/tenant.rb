module Cenit
  module Oauth
    module Tenant
      extend ActiveSupport::Concern

      def clean_up
        ApplicationId.where(:id.in => Cenit::Oauth.app_model.with(self).all.collect(&:application_id_id)).delete_all
      end
    end
  end
end