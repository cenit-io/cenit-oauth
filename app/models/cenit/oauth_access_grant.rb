module Cenit
  class OauthAccessGrant
    include Mongoid::Document
    include Cenit::MultiTenancy::Scoped

    belongs_to :application_id, class_name: Cenit::ApplicationId.to_s, inverse_of: nil
    field :scope, type: String

    after_destroy do
      [
        OauthAccessToken,
        OauthRefreshToken
      ].each do |oauth_token_model|
        oauth_token_model.where(tenant: Account.current, application_id: application_id).delete_all
      end
    end
  end
end