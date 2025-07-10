# frozen_string_literal: true

# lib/active_statsd/client.rb
require 'socket'

module ActiveStatsD
  # Client for sending metrics to a StatsD server via UDP.
  class Client
    attr_reader :host, :port, :namespace, :socket

    def initialize(host:, port:, namespace:)
      @host = host
      @port = port
      @namespace = namespace
      @socket = UDPSocket.new
    end

    def increment(metric, value = 1, tags: nil, sample_rate: 1.0)
      send_metric("#{metric}:#{value}|c", tags: tags, sample_rate: sample_rate)
    end

    def gauge(metric, value, tags: nil, sample_rate: 1.0)
      send_metric("#{metric}:#{value}|g", tags: tags, sample_rate: sample_rate)
    end

    def timing(metric, tags: nil, sample_rate: 1.0)
      start = Time.current
      yield
      elapsed = ((Time.current - start) * 1000).round
      send_metric("#{metric}:#{elapsed}|ms", tags: tags, sample_rate: sample_rate)
    end

    private

    def send_metric(payload, tags: nil, sample_rate: 1.0)
      namespaced_payload = "#{@namespace}.#{payload}"
      namespaced_payload += "|@#{sample_rate}" if sample_rate < 1.0
      namespaced_payload += "|##{format_tags(tags)}" if tags
      socket.send(namespaced_payload, 0, @host, @port)
    end

    def format_tags(tags)
      tags.map { |k, v| "#{k}:#{v}" }.join(',')
    end
  end
end
