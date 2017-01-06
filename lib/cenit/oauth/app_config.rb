module Cenit
  module Oauth
    module AppConfig
      extend ActiveSupport::Concern

      BANED_PARAMETER_NAMES = %w(authentication_method logo redirect_uris)

      included do

        Cenit::Oauth.app_model self

        belongs_to :application_id, class_name: ApplicationId.to_s, inverse_of: nil

        embeds_many :application_parameters, class_name: Cenit::ApplicationParameter.to_s, inverse_of: :application
        Cenit::ApplicationParameter.embedded_in :application, class_name: self.to_s, inverse_of: :application_parameters

        field :secret_token, type: String
        field :configuration_attributes, type: Hash, default: {}

        before_save do
          self.application_id ||= ApplicationId.create
          self.secret_token ||= Cenit::Token.friendly(60)

          if new_record?
            configuration['authentication_method'] ||= 'User credentials'
          end

          if configuration['logo'].blank?
            configuration['logo'] = Identicon.data_url_for identifier
          end

          self.class.configuration_callbacks.each do |callback|
            instance_eval(&callback)
          end

          validates_configuration.each do |error|
            errors.add(:base, error)
          end

          errors.blank?
        end

        after_destroy { application_id && application_id.destroy }

      end

      def validates_configuration
        JSON::Validator.fully_validate(configuration_schema, configuration_attributes, errors_as_objects: true).collect do |error|
          error[:message]
        end
      end

      def registered
        application_id && application_id.registered
      end

      def registered?
        registered
      end

      def identifier
        application_id && application_id.identifier
      end

      def slug_id
        application_id && (application_id.slug.presence || application_id.identifier)
      end

      def configuration
        configuration_attributes
      end

      def authentication_method
        configuration['authentication_method'].to_s.underscore.gsub(/ +/, '_').to_sym
      end

      def configuration_schema
        schema =
          {
            type: 'object',
            properties: properties = {
              authentication_method: {
                type: 'string',
                enum: ['User credentials', 'Application ID'],
                group: 'Security',
                default: 'User credentials'
              },
              logo: {
                type: 'string',
                group: 'UI'
              },
              redirect_uris: {
                type: 'array',
                items: {
                  type: 'string'
                },
                group: 'OAuth'
              }
            },
            required: required = %w(authentication_method)
          }
        required << 'redirect_uris' if registered?
        application_parameters.each { |p| properties[p.name] = p.schema }
        schema.deep_stringify_keys
      end

      def oauth_name
        fail NotImplementedError
      end

      module ClassMethods

        def before_validates_configuration(&block)
          block && configuration_callbacks << block
        end

        def configuration_callbacks
          @configuration_callbacks ||= []
        end

        def additional_parameter_types
          []
        end

        def parameter_type_schema(type)
          {
            '$ref': type.to_s
          }
        end
      end
    end
  end
end