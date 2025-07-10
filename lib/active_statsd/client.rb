# lib/active_statsd/client.rb
require 'socket'

module ActiveStatsD
  class Client
    def initialize(host:, port:, namespace:)
      @host = host
      @port = port
      @namespace = namespace
      @socket = UDPSocket.new
    end

    def increment(metric, by: 1)
      send_metric("#{metric}:#{by}|c")
    end

    def gauge(metric, value)
      send_metric("#{metric}:#{value}|g")
    end

    def timing(metric)
      start_time = Time.now
      yield
    ensure
      duration = ((Time.now - start_time) * 1000).round
      send_metric("#{metric}:#{duration}|ms")
    end

    private

    def send_metric(data)
      namespaced_data = "#{@namespace}.#{data}"
      @socket.send(namespaced_data, 0, @host, @port)
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Client error: #{e.message}"
    end
  end
end
