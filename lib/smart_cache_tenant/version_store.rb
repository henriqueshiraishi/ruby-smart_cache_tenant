# frozen_string_literal: true

module SmartCacheTenant
  class VersionStore
    def self.current(model_klass, tenant_id = nil)
      key = build_key(model_klass, tenant_id)
      Rails.cache.fetch(key, expires_in: SmartCacheTenant.config.ttl) { generate_version }
    end

    def self.bump!(model_klass, tenant_id = nil)
      key = build_key(model_klass, tenant_id)

      if SmartCacheTenant.config.tenant_column.present? && tenant_id.blank?
        Rails.cache.delete_matched("#{key}:*")
      else
        new_version = generate_version
        Rails.cache.write(key, new_version, expires_in: SmartCacheTenant.config.ttl)
        new_version
      end
    end

    def self.build_key(model_klass, tenant_id = nil)
      database_name = model_klass.connection_db_config.database
      tenant_column = SmartCacheTenant.config.tenant_column

      parts = [database_name, 'smart_cache', 'table_version', model_klass.table_name]
      parts << "#{tenant_column}:#{tenant_id}" if tenant_id.present? && tenant_column.present?
      parts.join(':').downcase
    end

    def self.generate_version
      Time.zone.now.strftime('%d%m%Y%H%M%S%L')
    end
  end
end
