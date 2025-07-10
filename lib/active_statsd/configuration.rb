# frozen_string_literal: true

# lib/active_statsd/configuration.rb
module ActiveStatsD
  # Configuration class for ActiveStatsD settings.
  class Configuration
    attr_accessor :host, :port, :namespace, :aggregation, :forward_host, :forward_port

    def initialize
      @host = '127.0.0.1'
      @port = 8125
      @namespace = 'rails_app'
      @aggregation = true  # Aggregation enabled by default
      @forward_host = nil  # Set if forwarding
      @forward_port = nil
    end
  end
end
