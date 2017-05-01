module Cenit
  class OauthAccessGrant
    include Mongoid::Document
    include Cenit::MultiTenancy::Scoped

    belongs_to :application_id, class_name: Cenit::ApplicationId.to_s, inverse_of: nil
    field :scope, type: String

    attr_readonly :application_id_id

    before_save :validate_scope

    after_destroy :clear_oauth_tokens

    def validate_scope
      if (scope = oauth_scope.access_by_ids).valid?
        self.scope = scope.to_s
      else
        errors.add(:scope, 'is not valid')
      end
      errors.blank?
    end

    def oauth_scope
      Cenit::OauthScope.new(scope)
    end

    def clear_oauth_tokens
      [
        OauthAccessToken,
        OauthRefreshToken
      ].each do |oauth_token_model|
        oauth_token_model.where(tenant: Account.current, application_id: application_id).delete_all
      end
    end
  end
end