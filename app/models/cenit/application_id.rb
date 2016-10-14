module Cenit
  class ApplicationId
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :tenant, class_name: Cenit::MultiTenancy.tenant_model_name, inverse_of: nil

    field :identifier, type: String
    field :oauth_name, type: String
    field :slug, type: String

    validates_length_of :oauth_name, :slug, within: 6..20, allow_blank: true
    validates_format_of :slug, with: /\A([a-z](_|-)?)*\Z/
    validates_uniqueness_of :oauth_name, conditions: -> { all.and(:oauth_name.exists => true) }
    validates_uniqueness_of :slug, conditions: -> { all.and(:slug.exists => true) }

    before_save do
      self.tenant = Cenit::MultiTenancy.tenant_model.current_tenant
      self.identifier ||= (id.to_s + Token.friendly(60))
      if @redirect_uris
        app.configuration['redirect_uris'] = @redirect_uris
        unless app.save
          app.errors.full_messages.each { |error| errors.add(:base, "Invalid configuration: #{error}") }
        end
      end
      errors.blank?
    end

    before_destroy do
      if app
        errors.add(:base, 'User App is present')
        false
      else
        true
      end
    end

    def app
      @app ||= tenant && Cenit::Oauth.app_model.with(tenant).where(application_id: self).first
    end

    def name
      oauth_name || (app && app.oauth_name)
    end

    def redirect_uris
      @redirect_uris ||
        begin
          config_attrs = app.configuration_attributes || {}
          redirect_uris = config_attrs['redirect_uris'] || []
          redirect_uris = [redirect_uris.to_s] unless redirect_uris.is_a?(Enumerable)
          redirect_uris
        end
    end

    def redirect_uris=(uris)
      if uris.is_a?(String)
        uris = JSON.parse(uris) rescue [uris]
      end
      uris = [uris.to_s] unless uris.is_a?(Enumerable)
      @redirect_uris = uris.collect(&:to_s)
    end

    def registered
      registered?
    end

    def registered?
      oauth_name.present?
    end

    def regist_with(data)
      [:slug, :oauth_name, :redirect_uris].each { |field| send("#{field}=", data[field]) }
      self
    end
  end
end