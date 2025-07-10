# frozen_string_literal: true

# lib/active_statsd/server.rb
require 'socket'
require 'concurrent'

module ActiveStatsD
  # Server for receiving metrics from StatsD clients via UDP.
  class Server
    def initialize(host:, port:, aggregation:, forward_host:, forward_port:)
      @host = host
      @port = port
      @aggregation = aggregation
      @forward_host = forward_host
      @forward_port = forward_port

      @counters = Concurrent::Hash.new { |hash, key| hash[key] = Concurrent::AtomicFixnum.new(0) }
      @forward_socket = UDPSocket.new if forwarding_enabled?
      @running = Concurrent::AtomicBoolean.new(false)
    end

    def start
      return if @running.true? # clearly avoid duplicate startup attempts

      Thread.new do
        sockets = initialize_server
        run_server_loop(sockets) if sockets
      rescue StandardError => e
        Rails.logger.error "[ActiveStatsD] Server error: #{e.class.name} - #{e.message}\n#{e.backtrace.join("\n")}"
      ensure
        @running.make_false
      end
    end

    private

    def initialize_server
      sockets = setup_sockets
      return unless sockets

      @running.make_true
      Rails.logger.info "[ActiveStatsD] UDP StatsD listener started on #{@host}:#{@port} (aggregation=#{@aggregation})"
      start_aggregation_thread if aggregation_enabled?
      sockets
    end

    def setup_sockets
      Socket.udp_server_sockets(@host, @port)
    rescue Errno::EADDRINUSE
      Rails.logger.warn "[ActiveStatsD] Server already running on #{@host}:#{@port}, skipping startup."
      nil
    end

    def run_server_loop(sockets)
      Socket.udp_server_loop_on(sockets) do |msg, _|
        Rails.logger.debug "[ActiveStatsD] UDP packet received: #{msg.strip}"
        handle_message(msg.strip)
      end
    ensure
      sockets.each(&:close)
    end

    def handle_message(message)
      metric, value, type = parse_metric(message)
      return unless metric && %w[c g ms].include?(type)

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

    def start_aggregation_thread
      Thread.new do
        loop do
          sleep 10 # configurable interval could be added later
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

    def forward_message(message)
      @forward_socket.send(message, 0, @forward_host, @forward_port)
    rescue StandardError => e
      Rails.logger.error "[ActiveStatsD] Forwarding error: #{e.message}"
    end

    def log_message(metric, value, type)
      Rails.logger.info "[ActiveStatsD] Metric received (no aggregation) - #{metric}:#{value}|#{type}"
    end
  end
end
