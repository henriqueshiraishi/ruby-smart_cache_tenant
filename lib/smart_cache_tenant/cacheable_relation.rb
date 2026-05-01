# frozen_string_literal: true

module SmartCacheTenant
  module CacheableRelation
    def load(&block)
      return super unless smart_cache_enabled?

      key = smart_cache_key(operation: :load)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      cached = Rails.cache.read(key)

      unless cached.nil?
        @records = cached
        @loaded = true
        SmartCacheTenant::Logger.log_cache_hit("#{klass.name} Load", elapsed_ms(started), arel_to_sql)
        return self
      end

      super.tap do
        Rails.cache.write(key, @records, expires_in: SmartCacheTenant.config.ttl)
      end
    end

    def calculate(operation, column_name)
      return super unless smart_cache_enabled?

      key = smart_cache_key(operation: "calculate:#{operation}:#{column_name}")
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      cached = Rails.cache.read(key)

      unless cached.nil?
        SmartCacheTenant::Logger.log_cache_hit("#{klass.name} #{operation.to_s.capitalize}", elapsed_ms(started), arel_to_sql)
        return cached
      end

      super.tap do |result|
        Rails.cache.write(key, result, expires_in: SmartCacheTenant.config.ttl)
      end
    end

    def exists?(conditions = :none)
      return super unless smart_cache_enabled?

      key = smart_cache_key(operation: "exists:#{conditions.inspect}")
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      cached = Rails.cache.read(key)

      unless cached.nil?
        SmartCacheTenant::Logger.log_cache_hit("#{klass.name} Exists?", elapsed_ms(started), arel_to_sql)
        return cached
      end

      super.tap do |result|
        Rails.cache.write(key, result, expires_in: SmartCacheTenant.config.ttl)
      end
    end

    def update_all(updates)
      result = super
      bump_smart_cache_for_bulk_write!(affected_rows: result)
      result
    end

    def insert_all(attributes, returning: nil, unique_by: nil, record_timestamps: nil)
      result = super
      bump_smart_cache_for_bulk_write!(tenant_ids: tenant_ids_from_bulk_attributes(attributes)) if attributes.present?
      result
    end

    def upsert_all(attributes, on_duplicate: :update, update_only: nil, returning: nil, unique_by: nil, record_timestamps: nil)
      result = super
      bump_smart_cache_for_bulk_write!(tenant_ids: tenant_ids_from_bulk_attributes(attributes)) if attributes.present?
      result
    end

    private

    def smart_cache_enabled?
      SmartCacheTenant.config.enabled && involved_models.all? { |model| model.try(:smart_cache_enabled?) }
    end

    def smart_cache_key(operation:)
      versions = involved_models.map do |model|
        "#{model.table_name}:#{SmartCacheTenant::VersionStore.current(model, resolve_tenant_id)}"
      end

      payload = {
        versions: versions.sort,
        tenant_id: resolve_tenant_id.to_s,
        sql_fingerprint: arel_to_sql,
        operation: operation.to_s
      }

      digest = if defined?(CityHash) && CityHash.respond_to?(:hash128)
                  CityHash.hash128(payload.to_json)
                else
                  Digest::SHA1.hexdigest(payload.to_json)
                end

      database_name = klass.connection_db_config.database
      [database_name, 'smart_cache', 'query', digest].join(':').downcase
    end

    def involved_models
      @involved_models ||= begin
        models = [klass]

        if eager_load_values.any? || joins_values.any? || left_outer_joins_values.any? || includes_values.any?
          all_associations = eager_load_values + joins_values + left_outer_joins_values + includes_values
          all_associations.each do |association_tree|
            collect_association_models(klass, association_tree, models)
          end
        end

        models.uniq
      end
    end

    def collect_association_models(current_model, association_tree, models)
      case association_tree
      when Symbol, String
        add_association_model(current_model, association_tree, models)
      when Array
        association_tree.each do |nested_association|
          collect_association_models(current_model, nested_association, models)
        end
      when Hash
        association_tree.each do |association_name, nested_association|
          reflection = add_association_model(current_model, association_name, models)
          next unless reflection
          collect_association_models(reflection.klass, nested_association, models)
        end
      end
    end

    def add_association_model(current_model, association_name, models)
      return unless association_name.respond_to?(:to_sym)

      reflection = current_model.reflect_on_association(association_name.to_sym)
      return unless reflection

      models << reflection.klass
      reflection
    end

    def arel_to_sql
      klass.connection.unprepared_statement { to_sql }
    end

    def elapsed_ms(started)
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0
    end

    def resolve_tenant_id
      tenant_column = SmartCacheTenant.config.tenant_column
      return if tenant_column.blank?

      where_values_hash[tenant_column.to_s] || where_values_hash["#{klass.table_name}.#{tenant_column}"]
    rescue StandardError
      nil
    end

    def tenant_ids_from_bulk_attributes(attributes)
      tenant_column = SmartCacheTenant.config.tenant_column
      return [] if tenant_column.blank?

      Array(attributes).filter_map do |row|
        next unless row.respond_to?(:[])

        row[tenant_column] || row[tenant_column.to_sym] || row[tenant_column.to_s]
      end.uniq
    end

    def bump_smart_cache_for_bulk_write!(tenant_ids: nil, affected_rows: nil)
      return unless klass.try(:smart_cache_enabled?)
      return if affected_rows.respond_to?(:zero?) && affected_rows.zero?

      resolved_tenant_ids = Array(tenant_ids).compact
      resolved_tenant_ids << resolve_tenant_id
      resolved_tenant_ids = resolved_tenant_ids.compact.uniq

      if resolved_tenant_ids.empty?
        SmartCacheTenant::VersionStore.bump!(klass)
      else
        resolved_tenant_ids.each { |tenant_id| SmartCacheTenant::VersionStore.bump!(klass, tenant_id) }
      end
    end
  end
end
