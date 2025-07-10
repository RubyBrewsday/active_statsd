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
      metric_data, type = message.split('|', 2)
      metric, value = metric_data&.split(':', 2)
      raise ArgumentError, 'Invalid metric format' unless metric && value && type

      [metric, Integer(value), type]
    rescue StandardError => e
      Rails.logger.error("[ActiveStatsD] Failed to parse metric: #{message} (#{e.message})")
      nil
    end

    def forward_message(message)
      @forward_socket.send(message, 0, @forward_host, @forward_port)
    rescue StandardError => e
      Rails.logger.error("[ActiveStatsD] Forwarding error: #{e.message}")
    end

    def log_message(metric, value, type)
      Rails.logger.info("[ActiveStatsD] Metric received (no aggregation) - #{metric}:#{value}|#{type}")
    end
  end

  # Socket handling functionality for the StatsD server.
  module SocketHandler
    def create_and_bind_socket
      socket = UDPSocket.new(Socket::AF_INET)
      socket.bind(@host, @port)
      socket
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Socket bind error: #{e.class} - #{e.message}"
      nil
    end

    def configure_socket_buffer(socket)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVBUF, 2**20)
    rescue StandardError => e
      Rails.logger.warn "[ActiveStatsD] Could not set SO_RCVBUF: #{e.message}"
    end

    def listen_for_messages(socket)
      until @shutdown.true?
        next unless socket.wait_readable(1)

        process_socket_message(socket)
      end
    end

    def process_socket_message(socket)
      data, _peer = socket.recvfrom_nonblock(4096)
      handle_message(data.strip)
    rescue IO::WaitReadable
      # Continue to next iteration
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Listener error: #{e.class} - #{e.message}"
    end
  end

  # UDP server for receiving and handling StatsD metrics.
  class Server
    include MetricHandler
    include SocketHandler

    def initialize(config)
      initialize_config(config)
      initialize_state
    end

    # Start the server: bind socket and begin listening and flushing
    def start
      return if @running.true?

      setup_signal_handlers
      @running.make_true
      Rails.logger.info("[ActiveStatsD] Server started on #{@host}:#{@port} (aggregation=#{@aggregation})")

      start_flush_task if aggregation_enabled?
      Concurrent.global_io_executor.post { run_udp_listener }
    end

    # Stop the server: signal shutdown and flush remaining metrics
    def stop
      Rails.logger.info '[ActiveStatsD] Shutting down UDP listener...'
      @shutdown.make_true
      stop_flush_task if aggregation_enabled?
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
      @counters = Concurrent::Hash.new { |h, k| h[k] = Concurrent::AtomicFixnum.new(0) }
      @forward_socket = UDPSocket.new if forwarding_enabled?
      @running = Concurrent::AtomicBoolean.new(false)
      @shutdown = Concurrent::AtomicBoolean.new(false)
    end

    def setup_signal_handlers
      %w[INT TERM].each { |sig| Signal.trap(sig) { stop } }
    end

    def start_flush_task
      @flush_task = Concurrent::TimerTask.new(
        execution_interval: @flush_interval,
        timeout_interval: (@flush_interval / 2.0)
      ) { flush_metrics }
      @flush_task.execute
    end

    def stop_flush_task
      @flush_task.shutdown
    end

    def run_udp_listener
      Rails.logger.info "[ActiveStatsD] UDP listener running on #{@host}:#{@port}..."
      socket = create_and_bind_socket
      return unless socket

      configure_socket_buffer(socket)
      listen_for_messages(socket)
    ensure
      socket.close if socket && !socket.closed?
      @running.make_false
      Rails.logger.info '[ActiveStatsD] UDP listener stopped.'
    end

    def flush_metrics
      snapshot = {}
      @counters.each_pair do |metric, atomic|
        count = atomic.value
        snapshot[metric] = count if count.positive?
        atomic.value = 0
      end
      snapshot.each do |metric, count|
        Rails.logger.info("[ActiveStatsD] Aggregated metric - #{metric}: #{count}")
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
