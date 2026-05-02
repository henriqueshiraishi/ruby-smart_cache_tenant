# frozen_string_literal: true

require 'rails/railtie'

module SmartCacheTenant
  class Railtie < Rails::Railtie
    initializer 'smart_cache.initialize' do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Relation.prepend(SmartCacheTenant::CacheableRelation)
        ActiveRecord::Base.singleton_class.prepend(SmartCacheTenant::CacheablePersistence)
      end
    end
  end
end
