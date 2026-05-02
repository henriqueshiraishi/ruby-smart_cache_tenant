# frozen_string_literal: true

require_relative "lib/smart_cache_tenant/version"

Gem::Specification.new do |spec|
  spec.name = "smart_cache_tenant"
  spec.version = SmartCacheTenant::VERSION
  spec.authors = ["Henrique A. Shiraishi"]
  spec.email = ["henriqueashiraishi@gmail.com"]

  spec.summary = "Tenant-aware query caching for ActiveRecord."
  spec.description = "SmartCacheTenant adds tenant-aware query caching on top of ActiveRecord by storing cached read results in Rails.cache and invalidating them through lightweight version keys."
  spec.homepage = "https://github.com/henriqueshiraishi/ruby-smart_cache_tenant"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/henriqueshiraishi/ruby-smart_cache_tenant"
  spec.metadata["changelog_uri"] = "https://github.com/henriqueshiraishi/ruby-smart_cache_tenant/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0", "< 8.0"

  spec.add_development_dependency "sqlite3", "~> 1.7"
  spec.add_development_dependency "rspec", "~> 3.13"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
