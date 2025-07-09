# frozen_string_literal: true

require 'active_statsd/version'
require 'active_statsd/configuration'
require 'active_statsd/server'
require 'active_statsd/client'
require 'active_statsd/rails_integration'
require 'active_statsd/railtie' if defined?(Rails)

# lib/active_statsd.rb
require 'active_statsd/version'
require 'active_statsd/configuration'
require 'active_statsd/server'
require 'active_statsd/client'
require 'active_statsd/rails_integration'
require 'active_statsd/railtie' if defined?(Rails)

module ActiveStatsD
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def client
      @client ||= Client.new(
        host: configuration.host,
        port: configuration.port,
        namespace: configuration.namespace
      )
    end
  end
end
