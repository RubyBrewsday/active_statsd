# frozen_string_literal: true

# lib/active_statsd/server.rb
require 'socket'
require 'concurrent'
require 'json'

module ActiveStatsD
  # Metric handling functionality for the StatsD server.
  module MetricHandler
    def handle_message(message)
      metric, value, type = parse_metric(message)
      if metric.nil?
        Rails.logger.warn({ event: 'invalid_metric', raw_message: message }.to_json)
        return
      end

      process_metric(metric, value, type, message)
    rescue StandardError => e
      Rails.logger.error({ event: 'unexpected_error', error: e.message, backtrace: e.backtrace }.to_json)
    end

    def process_metric(metric, value, type, message)
      @counters[metric].increment(value) if aggregation_enabled?

      forward_message(message) if forwarding_enabled?
      log_message(metric, value, type) unless aggregation_enabled?
    end

    def parse_metric(message)
      metric_data, type = message.split('|')
      metric, value = metric_data&.split(':')
      raise ArgumentError, 'Invalid metric format' unless metric && value && type

      [metric, Integer(value), type]
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Failed to parse metric: #{message} (#{e.message})"
      nil
    end

    def forward_message(message)
      @forward_socket.send(message, 0, @forward_host, @forward_port)
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Forwarding error: #{e.message}"
    end

    def log_message(metric, value, type)
      Rails.logger.info "[ActiveStatsD] Metric received (no aggregation) - #{metric}:#{value}|#{type}"
    end
  end

  # Server for receiving metrics from StatsD clients via UDP.
  class Server
    include MetricHandler

    def initialize(config)
      initialize_config(config)
      initialize_state
    end

    def start
      return if @running.true?

      setup_signal_handlers
      Thread.new { run_udp_listener }
      start_aggregation_thread if aggregation_enabled?
    end

    def stop
      Rails.logger.info '[ActiveStatsD] Shutting down UDP listener...'
      @shutdown.make_true
      flush_metrics if aggregation_enabled?
      Rails.logger.info '[ActiveStatsD] Shutdown complete.'
    end

    private

    def initialize_config(config)
      @host = config.host
      @port = config.port
      @aggregation = config.aggregation
      @forward_host = config.forward_host
      @forward_port = config.forward_port
      @flush_interval = config.flush_interval
    end

    def initialize_state
      @counters = Concurrent::Hash.new { |hash, key| hash[key] = Concurrent::AtomicFixnum.new(0) }
      @forward_socket = UDPSocket.new if forwarding_enabled?
      @running = Concurrent::AtomicBoolean.new(false)
      @shutdown = Concurrent::AtomicBoolean.new(false)
    end

    def setup_signal_handlers
      %w[INT TERM].each do |signal|
        Signal.trap(signal) { stop }
      end
    end

    def run_udp_listener
      @running.make_true
      Rails.logger.info '[ActiveStatsD] UDP listener running...'
      run_socket_loop
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Listener error: #{e.message}"
    ensure
      @running.make_false
    end

    def run_socket_loop
      sockets = Socket.udp_server_sockets(@host, @port)
      Socket.udp_server_loop_on(sockets) do |msg, _|
        break if @shutdown.true?

        handle_message(msg.strip)
      end
    ensure
      sockets.each(&:close)
    end

    def start_aggregation_thread
      Thread.new do
        loop do
          sleep @flush_interval
          flush_metrics
        end
      end
    end

    def flush_metrics
      snapshot = {}

      @counters.each_pair do |metric, atomic_count|
        count = atomic_count.value
        snapshot[metric] = count if count.positive?
        atomic_count.value = 0
      end

      snapshot.each do |metric, count|
        Rails.logger.info "[ActiveStatsD] Aggregated metric - #{metric}: #{count}"
      end
    end

    def forwarding_enabled?
      @forward_host && @forward_port
    end

    def aggregation_enabled?
      @aggregation
    end
  end
end
