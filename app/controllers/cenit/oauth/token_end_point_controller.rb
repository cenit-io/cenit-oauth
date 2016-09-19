require 'account'
require 'user'
require 'setup/application'

module Cenit
  module Oauth
    class TokenEndPointController < ApplicationController

      def index
        response = {}
        response_code = :bad_request
        errors = ''
        token_class =
          case (grant_type = params[:grant_type])
          when 'authorization_code'
            errors += 'Code missing. ' unless (auth_value = params[:code])
            Cenit::OauthCodeToken
          when 'refresh_token'
            errors += 'Refresh token missing. ' unless (auth_value = params[:refresh_token])
            Cenit::OauthRefreshToken
          else
            errors += 'Invalid grant_type parameter.'
            nil
          end
        if errors.blank? && (token = token_class.where(token: auth_value).first)
          token.set_current_tenant!
          token.destroy unless token.long_term?
          if (app_id = Cenit::ApplicationId.where(identifier: params[:client_id]).first) &&
            app_id.app.secret_token == params[:client_secret]
            if grant_type == 'authorization_code'
              errors += 'Invalid redirect_uri. ' unless app_id.nil? || app_id.redirect_uris.include?(params[:redirect_uri])
            end
          else
            errors += 'Invalid client credentials. '
          end
          begin
            response = Cenit::OauthAccessToken.for(app_id, token.scope, token.user_id, token.tenant)
            response_code = :ok
          rescue Exception => ex
            errors += ex.message
          end if errors.blank?
        else
          errors += "Invalid #{grant_type.gsub('_', ' ')}." if token_class
        end
        response = { error: errors } if errors.present?
        render json: response, status: response_code
      end
    end
  end
end
