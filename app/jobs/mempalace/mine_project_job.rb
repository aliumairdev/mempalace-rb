# frozen_string_literal: true

module Mempalace
  class MineProjectJob < ActiveJob::Base
    queue_as :default

    def perform(tenant_id:, path:, wing: nil, options: {})
      Mempalace.mine_project(tenant: tenant_id, path: path, wing: wing, async: false, **options.symbolize_keys)
    end
  end
end
