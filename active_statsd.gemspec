# frozen_string_literal: true

require_relative "lib/active_statsd/version"

Gem::Specification.new do |spec|
  spec.name = "active_statsd"
  spec.version = ActiveStatsd::VERSION
  spec.authors = ["Mike Poage"]
  spec.email = ["michael.poage@beehiiv.com"]

  spec.summary = "ActiveStatsd is a gem that provides a Rails-friendly interface for StatsD."
  spec.description = "ActiveStatsd is a gem that provides a Rails-friendly interface for StatsD."
  spec.homepage = "https://github.com/beehiiv/active_statsd"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # active_statsd.gemspec
  spec.add_dependency 'statsd-ruby'
  spec.add_dependency 'rails', '>= 5.0'

  # Development dependencies (for testing)
  spec.add_development_dependency 'rspec-rails'

end
