module Cenit
  module OauthGrantToken
    extend ActiveSupport::Concern

    include OauthTokenCommon

    included do
      belongs_to :application_id, class_name: ApplicationId.to_s, inverse_of: nil
    end

    def access_grant
      @access_grant ||= Cenit::OauthAccessGrant.with(tenant).where(application_id: application_id).first
    end

    def scope
      access_grant.scope
    end
  end
end