# frozen_string_literal: true

require "bundler/setup"
ENV["RAILS_ENV"] ||= "test"

require "logger"
require "rails"
require "active_record"
require "active_support/all"
require "smart_cache_tenant"

unless defined?(Rails.application) && Rails.application
  class SmartCacheTenantTestApp < Rails::Application
    config.root = Dir.pwd
    config.eager_load = false
    config.logger = Logger.new($stdout)
    config.secret_key_base = "smart-cache-tenant-test"
    config.cache_store = :memory_store
    config.consider_all_requests_local = true
  end

  Rails.application.initialize!
end

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

SmartCacheTenant.configure do |config|
  config.enabled = true
  config.ttl = 1.hour
  config.tenant_column = :tenant_id
  config.log_queries = false
end

RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table :projects, force: true do |t|
          t.integer :tenant_id
          t.string :name
          t.timestamps null: false
        end
      end
    end

    unless defined?(Project)
      class Project < ActiveRecord::Base
        include SmartCacheTenant::ModelCallbacks
        has_smart_cache
      end
    end
  end

  config.before do
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
    Project.delete_all if defined?(Project)
  end
end
