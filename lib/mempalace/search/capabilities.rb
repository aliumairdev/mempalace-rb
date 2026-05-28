# frozen_string_literal: true

module Mempalace
  module Search
    module Capabilities
      module_function

      def postgresql?
        Mempalace::Drawer.connection.adapter_name.downcase.include?("postgres")
      rescue ActiveRecord::ConnectionNotEstablished
        false
      end

      def sqlite?
        Mempalace::Drawer.connection.adapter_name.downcase.include?("sqlite")
      rescue ActiveRecord::ConnectionNotEstablished
        false
      end

      def search_vector?
        Mempalace::Drawer.column_names.include?("search_vector")
      rescue ActiveRecord::ConnectionNotEstablished
        false
      end

      def vector?
        postgresql? && Mempalace::Drawer.columns_hash["embedding"]&.sql_type.to_s.start_with?("vector")
      rescue ActiveRecord::ConnectionNotEstablished
        false
      end
    end
  end
end
