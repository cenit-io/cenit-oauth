require 'jwt'

module Cenit
  class OauthAccessToken < BasicToken
    include OauthGrantToken

    field :token_type, type: Symbol, default: :Bearer

    validates_inclusion_of :token_type, in: [:Bearer]

    class << self
      def for(app_id, scope, user_or_id, tenant = Cenit::MultiTenancy.tenant_model.current)
        user =
          if (user_model = Cenit::MultiTenancy.user_model) && user_or_id.is_a?(user_model)
            user_or_id
          else
            (user_model && user_model.where(id: user_or_id).first) || user_or_id
          end
        scope = Cenit::OauthScope.new(scope) unless scope.is_a?(Cenit::OauthScope)
        unless (access_grant = Cenit::OauthAccessGrant.with(tenant).where(application_id: app_id).first)
          access_grant = Cenit::OauthAccessGrant.with(tenant).new(application_id: app_id)
        end
        access_grant.scope = scope.to_s
        access_grant.save
        token = create(tenant: tenant, application_id: app_id, user_id: user.id)
        access =
          {
            access_token: token.token,
            token_type: token.token_type,
            created_at: token.created_at.to_i,
            token_span: token.token_span
          }
        if scope.offline_access? &&
          Cenit::OauthRefreshToken.where(tenant: tenant, application_id: app_id, user_id: user.id).blank?
          refresh_token = Cenit::OauthRefreshToken.create(tenant: tenant, application_id: app_id, user_id: user.id)
          access[:refresh_token] = refresh_token.token
        end
        if scope.openid?
          payload =
            {
              iss: Cenit.homepage,
              sub: user.id.to_s,
              aud: app_id.identifier,
              exp: access[:created_at] + access[:token_span],
              iat: access[:created_at],
            }
          if (scope.email? || scope.profile?) && user.confirmed? #TODO Include other OpenID scopes
            if user.respond_to?(:email) && (field_value = user.send(:email))
              payload[:email] = field_value
            end
            #TODO Family Name for Cenit Users
            # payload[:family_name] = user.family_name
            [
              :given_name
            ].each do |field|
              if user.respond_to?(field) && (field_value = user.send(field))
                payload[field] = field_value
              end
            end if scope.profile?
          end
          access[:id_token] = JWT.encode(payload, nil, 'none')
        end
        access
      end
    end
  end
end