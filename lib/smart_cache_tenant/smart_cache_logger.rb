# frozen_string_literal: true

module SmartCacheTenant
  module Logger
    RESET  = "\e[0m"
    BOLD   = "\e[1m"
    CYAN   = "\e[36m"
    BLUE   = "\e[34m"
    YELLOW = "\e[33m"

    def self.log_cache_hit(operation_name, duration_ms, sql)
      return unless should_log?

      opt_part = colorize("SMART CACHE #{operation_name} (#{format_duration(duration_ms)})", CYAN + BOLD)
      sql_part = colorize("  #{sql}", BLUE + BOLD)

      Rails.logger.debug("  #{opt_part}#{sql_part}")
    end

    private

    def self.should_log?
      SmartCacheTenant.config.log_queries && Rails.logger.debug? && !Rails.env.production?
    end

    def self.format_duration(ms)
      if ms >= 1000
        "#{(ms / 1000.0).round(1)}s"
      else
        "#{ms.round(1)}ms"
      end
    end

    def self.colorize(text, color_code)
      if ActiveSupport::LogSubscriber.colorize_logging
        "#{color_code}#{text}#{RESET}"
      else
        text
      end
    end
  end
end
