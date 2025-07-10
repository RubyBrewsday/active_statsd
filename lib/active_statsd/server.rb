# lib/active_statsd/server.rb
# frozen_string_literal: true

require 'socket'
require 'concurrent'
require 'json'

module ActiveStatsD
  # Handles parsing, aggregation, forwarding, and logging of metrics.
  module MetricHandler
    def handle_message(message)
      metric, value, type = parse_metric(message)
      if metric.nil?
        Rails.logger.warn({ event: 'invalid_metric', raw_message: message }.to_json)
        return
      end

      process_metric(metric, value, type, message)
    rescue StandardError => e
      Rails.logger.error(
        { event: 'unexpected_error', error: e.message, backtrace: e.backtrace }.to_json
      )
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
    rescue StandardError
      Rails.logger.error("[ActiveStatsD] Failed to parse metric: \#{message} (\#{e.message})")
      nil
    end

    def forward_message(message)
      @forward_socket.send(message, 0, @forward_host, @forward_port)
    rescue StandardError
      Rails.logger.error("[ActiveStatsD] Forwarding error: \#{e.message}")
    end

    def log_message(_metric, _value, _type)
      Rails.logger.info("[ActiveStatsD] Metric received (no aggregation) - \#{metric}:\#{value}|\#{type}")
    end
  end

  # UDP server for receiving and handling StatsD metrics.
  class Server
    include MetricHandler

    def initialize(config)
      initialize_config(config)
      initialize_state

      @flush_task = Concurrent::TimerTask.new(
        execution_interval: @flush_interval,
        timeout_interval: (@flush_interval / 2.0)
      ) { flush_metrics }
    end

    def start
      return if @running.true?

      setup_signal_handlers
      Concurrent.global_io_executor.post { run_udp_listener }
      @flush_task.execute if aggregation_enabled?
      @running.make_true
      Rails.logger.info(
        "[ActiveStatsD] Server started on \#{@host}:\#{@port} (aggregation=\#{@aggregation})"
      )
    end

    def stop
      Rails.logger.info '[ActiveStatsD] Shutting down UDP listener...'
      @shutdown.make_true
      @flush_task.shutdown if aggregation_enabled?
      flush_metrics if aggregation_enabled?
      Rails.logger.info '[ActiveStatsD] Shutdown complete.'
    end

    private

    def initialize_config(config)
      @host               = config.host
      @port               = config.port
      @aggregation        = config.aggregation
      @forward_host       = config.forward_host
      @forward_port       = config.forward_port
      @flush_interval     = config.flush_interval
    end

    def initialize_state
      @counters = Concurrent::Hash.new { |h, k| h[k] = Concurrent::AtomicFixnum.new(0) }
      @forward_socket = UDPSocket.new if forwarding_enabled?
      @running       = Concurrent::AtomicBoolean.new(false)
      @shutdown      = Concurrent::AtomicBoolean.new(false)
    end

    def setup_signal_handlers
      %w[INT TERM].each { |sig| Signal.trap(sig) { stop } }
    end

    def run_udp_listener
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

    def flush_metrics
      snapshot = {}

      @counters.each_pair do |metric, atomic_count|
        count = atomic_count.value
        snapshot[metric] = count if count.positive?
        atomic_count.value = 0
      end

      snapshot.each do |_metric, _count|
        Rails.logger.info("[ActiveStatsD] Aggregated metric - \#{metric}: \#{count}")
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
