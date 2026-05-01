# frozen_string_literal: true

module SmartCacheTenant
  class Configuration
    attr_accessor :enabled, :ttl, :tenant_column, :log_queries

    def initialize
      @enabled = true
      @ttl = 1.hour
      @tenant_column = nil
      @log_queries = !Rails.env.production?
    end
  end

  def self.config
    @config ||= SmartCacheTenant::Configuration.new
  end

  def self.configure
    yield config
  end
end
