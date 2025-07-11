# frozen_string_literal: true

require 'socket'
require 'concurrent'
require 'json'
require_relative 'handlers/metrics'
require_relative 'handlers/sockets'

module ActiveStatsD
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
