# frozen_string_literal: true

module SmartCacheTenant
  module CacheablePersistence
    def insert_all(attributes, returning: nil, unique_by: nil, record_timestamps: nil)
      result = super
      bump_smart_cache_for_class_bulk_write!(attributes)
      result
    end

    def upsert_all(attributes, on_duplicate: :update, update_only: nil, returning: nil, unique_by: nil, record_timestamps: nil)
      result = super
      bump_smart_cache_for_class_bulk_write!(attributes)
      result
    end

    private

    def bump_smart_cache_for_class_bulk_write!(attributes)
      return unless try(:smart_cache_enabled?)
      return if attributes.respond_to?(:empty?) && attributes.empty?

      tenant_column = SmartCacheTenant.config.tenant_column
      tenant_ids = Array(attributes).map do |row|
        next unless row.respond_to?(:[])
        next if tenant_column.blank?

        row[tenant_column] || row[tenant_column.to_sym] || row[tenant_column.to_s]
      end.compact_blank.uniq

      if tenant_ids.empty?
        SmartCacheTenant::VersionStore.bump!(self)
      else
        tenant_ids.each { |tenant_id| SmartCacheTenant::VersionStore.bump!(self, tenant_id) }
      end
    end
  end
end
