# frozen_string_literal: true

module Mempalace
  module Tenant
    module_function

    def resolve(tenant = nil)
      tenant ||= Mempalace.configuration.tenant_resolver&.call
      return Mempalace.configuration.single_tenant_id if tenant.nil? && Mempalace.configuration.single_tenant?

      raise MissingTenantError, "tenant is required" if tenant.nil?

      tenant
    end

    def id_for(tenant)
      tenant = resolve(tenant)
      return tenant if tenant.is_a?(Integer)
      return tenant.to_i if tenant.is_a?(String) && tenant.match?(/\A\d+\z/)
      return tenant.id if tenant.respond_to?(:id) && tenant.id.present?

      raise MissingTenantError, "tenant must be an id or respond to #id"
    end

    def foreign_key
      Mempalace.configuration.tenant_foreign_key.to_sym
    end

    def assignment_for(tenant)
      { foreign_key => id_for(tenant) }
    end

    def tenant_model_class
      Mempalace.configuration.tenant_model.to_s.constantize
    rescue NameError => e
      raise ConfigurationError, "tenant_model #{Mempalace.configuration.tenant_model.inspect} is not defined: #{e.message}"
    end

    def find_from_env!
      tenant_id = ENV["TENANT_ID"] || ENV.fetch("ACCOUNT_ID", nil)
      return Mempalace.configuration.single_tenant_id if tenant_id.blank? && Mempalace.configuration.single_tenant?

      raise MissingTenantError, "set TENANT_ID for this task" if tenant_id.blank?

      tenant_model_class.find(tenant_id)
    end
  end
end
