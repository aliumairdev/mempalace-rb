# frozen_string_literal: true

module Mempalace
  module Services
    class WakeUp
      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(tenant: nil, wing: nil, max_tokens: 1_500)
        @tenant = tenant
        @wing = wing
        @max_tokens = max_tokens
      end

      def call
        tenant = Mempalace::Tenant.resolve(@tenant)
        scope = Mempalace::Drawer.filtered(tenant: tenant, wing: @wing)
        recent = scope.order(filed_at: :desc, id: :desc).limit(8).includes(:wing, :room).to_a
        decisions = scope.of_memory_type("decision").order(filed_at: :desc, id: :desc).limit(8).includes(:wing, :room).to_a

        lines = []
        lines << "L0: identity/project overview"
        lines << "Tenant #{Mempalace.tenant_id_for(tenant)}#{" / wing #{Mempalace::Slugger.call(@wing)}" if @wing.present?}"
        lines << ""
        lines << "L1: critical decisions/facts"
        lines.concat(format_drawers(decisions.presence || recent.first(4)))
        lines << ""
        lines << "L2: recent/relevant room memories"
        lines.concat(format_drawers(recent))
        trim(lines.join("\n"))
      end

      private

      def format_drawers(drawers)
        drawers.map do |drawer|
          "[#{drawer.wing.slug} / #{drawer.room.slug} / #{drawer.memory_type}] #{drawer.content.to_s.strip.gsub(/\s+/, ' ')}"
        end
      end

      def trim(text)
        max_chars = [@max_tokens.to_i * 4, 200].max
        text.length > max_chars ? "#{text[0, max_chars]}\n[truncated]" : text
      end
    end
  end
end
