# frozen_string_literal: true

require_relative 'lib/active_statsd/version'

Gem::Specification.new do |spec|
  spec.name = 'active_statsd'
  spec.version = ActiveStatsD::VERSION
  spec.authors = ['Mike Poage']
  spec.email = ['poage.michael.cu@gmail.com']

  spec.summary = 'ActiveStatsD is a gem that provides a Rails-friendly interface for StatsD.'
  spec.description = 'ActiveStatsD is a gem that provides a Rails-friendly interface for StatsD.'
  spec.homepage = 'https://github.com/RubyBrewsday/active_statsd'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/RubyBrewsday/active_statsd'
  spec.metadata['changelog_uri'] = 'https://github.com/RubyBrewsday/active_statsd/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'async'
  spec.add_dependency 'concurrent-ruby'
  spec.add_dependency 'io-endpoint'
  spec.add_dependency 'rails', '>= 5.0'

  spec.add_development_dependency 'benchmark-ips', '~> 2.12'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop', '~> 1.63'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rails'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rubocop-rspec_rails'
  spec.add_development_dependency 'rubocop-thread_safety'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
