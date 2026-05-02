# frozen_string_literal: true

module SmartCacheTenant
  module ModelCallbacks
    extend ActiveSupport::Concern

    included do
      after_commit :bump_smart_cache_version!
    end

    class_methods do
      def smart_cache_enabled?
        @smart_cache_enabled == true
      end

      def has_smart_cache
        @smart_cache_enabled = true
      end

      def smart_cache_bump!(tenant_id = nil)
        SmartCacheTenant::VersionStore.bump!(self, tenant_id)
      end

      def smart_cached_version(tenant_id = nil)
        SmartCacheTenant::VersionStore.current(self, tenant_id)
      end
    end

    def smart_cache_bump!
      self.class.smart_cache_bump!(try(SmartCacheTenant.config.tenant_column))
    end

    def smart_cached_version
      self.class.smart_cached_version(try(SmartCacheTenant.config.tenant_column))
    end

    private

    def bump_smart_cache_version!
      return unless self.class.smart_cache_enabled?

      tenant_id = try(SmartCacheTenant.config.tenant_column)
      SmartCacheTenant::VersionStore.bump!(self.class, tenant_id)
    end
  end
end
