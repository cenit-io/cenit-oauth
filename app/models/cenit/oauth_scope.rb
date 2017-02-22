module Cenit
  class OauthScope

    def initialize(scope = '')
      @openid = Set.new
      @access = {}
      @super_methods = Set.new
      scope = scope.to_s.strip
      while scope.present?
        openid, scope = split(scope, %w(openid email profile address phone offline_access auth))
        @offline_access ||= openid.delete(:offline_access)
        @auth ||= openid.delete(:auth)
        @openid.merge(openid)
        if scope.present?
          methods, scope = split(scope, %w(get post put delete))
          methods = Set.new(methods)
          access = @access.delete(methods) || []
          criteria = {}
          if scope.present? && scope.start_with?('{')
            i = 1
            stack = 1
            while stack > 0 && i < scope.length
              case scope[i]
              when '{'
                stack += 1
              when '}'
                stack -= 1
              end
              i += 1
            end
            criteria = JSON.parse(scope[0, i])
            scope = scope.from(i)
          end
          if criteria.present?
            access << criteria
            @access[methods] = access
          else
            @super_methods.merge(methods)
          end
        end
        scope = scope.strip
      end
      @openid.clear if @openid.present? && !@openid.include?(:openid)
    rescue
      @access.clear
    end

    def valid?
      openid.present? || access.present?
    end

    def to_s
      if valid?
        s =
          (auth? ? 'auth ' : '') +
            (offline_access? ? 'offline_access ' : '') +
            (openid? ? openid.to_a.join(' ') + ' ' : '') +
            access.collect do |methods, access|
              methods_str = methods.to_a.join(' ')
              if access.present?
                access.collect do |criteria|
                  "#{methods_str} #{criteria.to_json}"
                end.join(' ')
              else
                methods_str
              end
            end.join(' ') + ' ' + super_methods.to_a.join(' ')
        s.strip
      else
        '<invalid scope>'
      end
    end

    def descriptions
      d = []
      if valid?
        d << 'View your email' if email?
        d << 'View your basic profile' if profile?
        access.each do |methods, access|
          access.each do |criteria|
            d << methods.to_a.to_sentence +
              ' records from data types where ' + criteria.to_json
          end
        end
        if super_methods.present?
          d << "#{super_methods.to_a.to_sentence} records from any data type"
        end
      else
        d << '<invalid scope>'
      end
      d
    end

    def auth?
      auth.present?
    end

    def openid?
      openid.include?(:openid)
    end

    def email?
      openid.include?(:email)
    end

    def profile?
      openid.include?(:profile)
    end

    def offline_access?
      offline_access.present?
    end

    def merge(other)
      merge = self.class.new
      merge.instance_variable_set(:@auth, auth || other.instance_variable_get(:@auth))
      merge.instance_variable_set(:@offline_access, offline_access || other.instance_variable_get(:@offline_access))
      merge.instance_variable_set(:@openid, (openid + other.instance_variable_get(:@openid)))
      merge.instance_variable_set(:@super_methods, super_methods + other.super_methods)
      [
        access,
        other.instance_variable_get(:@access)
      ].each do |access|
        access.each do |methods, other_accss|
          merge.merge_access(methods, other_accss)
        end
      end
      merge
    end

    protected

    attr_reader :auth, :offline_access, :openid, :methods, :nss, :data_types, :access, :super_methods

    def space(str)
      str.index(' ') ? "'#{str}'" : str
    end

    def split(scope, tokens)
      scope += ' '
      counters = Hash.new { |h, k| h[k] = 0 }
      while (method = tokens.detect { |m| scope.start_with?("#{m} ") })
        counters[method] += 1
        scope = scope.from(method.length).strip
      end
      if counters.values.all? { |v| v ==1 }
        [counters.keys.collect(&:to_sym), scope]
      else
        [[], scope]
      end
    end

    def merge_access(other_methods, other_access)
      other_methods = other_methods - super_methods
      if other_methods.present?
        (access[other_methods] ||= []).concat(other_access).uniq!
      end
    end
  end
end