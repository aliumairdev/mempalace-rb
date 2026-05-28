# frozen_string_literal: true

namespace :mempalace do
  desc "Show tenant-scoped MemPalace status. Requires TENANT_ID."
  task status: :environment do
    puts Mempalace.status(tenant: Mempalace::Tenant.find_from_env!).inspect
  end

  desc "Mine a project directory. Requires TENANT_ID and PATH."
  task mine_project: :environment do
    path = ENV["PATH"] || "."
    result = Mempalace.mine_project(tenant: Mempalace::Tenant.find_from_env!, path: path, wing: ENV.fetch("WING", nil))
    puts result.inspect
  end

  desc "Search memories. Requires TENANT_ID and QUERY."
  task search: :environment do
    query = ENV.fetch("QUERY", nil)
    raise Mempalace::ValidationError, "set QUERY" if query.blank?

    puts Mempalace.search(tenant: Mempalace::Tenant.find_from_env!, query: query, wing: ENV.fetch("WING", nil),
                          room: ENV.fetch("ROOM", nil)).inspect
  end

  desc "Retry failed embeddings. Requires TENANT_ID."
  task reembed_failed: :environment do
    tenant = Mempalace::Tenant.find_from_env!
    Mempalace::Drawer.for_tenant(tenant).embedding_failed.find_each do |drawer|
      Mempalace::ReindexDrawerJob.perform_later(drawer.id)
    end
    puts "Queued failed embeddings for tenant #{Mempalace.tenant_id_for(tenant)}"
  end
end
