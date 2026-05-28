# frozen_string_literal: true

module Mempalace
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    def self.tenant_foreign_key
      Mempalace::Tenant.foreign_key
    end

    def self.for_tenant(tenant)
      where(tenant_foreign_key => Mempalace.tenant_id_for(tenant))
    end

    def tenant_id
      public_send(self.class.tenant_foreign_key)
    end

    def tenant_id=(value)
      public_send("#{self.class.tenant_foreign_key}=", value)
    end
  end
end
