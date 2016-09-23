require 'identicon'

module Cenit
  module Oauth
    module User
      extend ActiveSupport::Concern

      include Cenit::MultiTenancy::UserScope

      def avatar_id
        try(:email) || try(:id)
      end

      def confirmed?
        false
      end

      def custom_picture_url(size=50)
        Cenit::Oauth.picture_url_for(self)
      end

      def gravatar()
        gravatar_check = "//gravatar.com/avatar/#{Digest::MD5.hexdigest(avatar_id.to_s.downcase)}.png?d=404"
        uri = URI.parse(gravatar_check)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new("/avatar/#{Digest::MD5.hexdigest(avatar_id.to_s.downcase)}.png?d=404")
        response = http.request(request)
        response.code.to_i < 400 # from d=404 parameter
      rescue
        false
      end

      def identicon(size=50)
        Identicon.data_url_for avatar_id.to_s.downcase, size
      end

      def gravatar_or_identicon_url(size=50)
        if gravatar()
          "//gravatar.com/avatar/#{Digest::MD5.hexdigest avatar_id.to_s}?s=#{size}"
        else
          identicon size
        end
      end

      def picture_url(size=50)
        custom_picture_url(size) || gravatar_or_identicon_url(size)
      end
    end
  end
end