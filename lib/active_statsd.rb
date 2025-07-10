# lib/active_statsd.rb
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
    # Yield the thread-local Configuration instance
    def configure
      yield configuration
    end

    # Always returns the same Configuration for the current thread
    def configuration
      Thread.current[:active_statsd_configuration] ||= Configuration.new
    end

    # Always returns the same Client for the current thread,
    # built from that thread’s Configuration
    def client
      Thread.current[:active_statsd_client] ||= begin
        cfg = configuration
        Client.new(host: cfg.host,
                   port: cfg.port,
                   namespace: cfg.namespace)
      end
    end
  end
end
