# frozen_string_literal: true

require 'active_statsd/version'
require 'active_statsd/configuration'
require 'active_statsd/server'
require 'active_statsd/client'
require 'active_statsd/rails_integration'
require 'active_statsd/railtie' if defined?(Rails)

# ActiveStatsD provides a simple interface for sending metrics to StatsD servers.
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
