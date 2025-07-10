# spec/spec_helper.rb
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'active_statsd'
require 'logger'
require 'active_support/core_ext/string/inflections'
require 'active_support/testing/time_helpers'
require 'active_support/isolated_execution_state'

# Mock Rails.logger explicitly unless Rails is loaded
unless defined?(Rails)
  module Rails
    LOGGER = Logger.new($stdout)

    def self.logger
      LOGGER
    end

    def self.stats
      ActiveStatsD.client
    end
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
