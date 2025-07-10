# lib/active_statsd/server.rb
require "socket"

module ActiveStatsD
  class Server
    def initialize(host:, port:, aggregation:, forward_host:, forward_port:)
      @host = host
      @port = port
      @aggregation = aggregation
      @forward_host = forward_host
      @forward_port = forward_port
      @counters = Hash.new(0)
      @mutex = Mutex.new
      @forward_socket = UDPSocket.new if forwarding_enabled?
      @running = false
    end

    def start
      return if @running  # Don't attempt to start twice

      Thread.new do
        begin
          sockets = Socket.udp_server_sockets(@host, @port)
        rescue Errno::EADDRINUSE
          Rails.logger.warn "[ActiveStatsD] Server already running on #{@host}:#{@port}, skipping startup."
          next
        end

        @running = true
        Rails.logger.info "[ActiveStatsD] UDP StatsD listener started on #{@host}:#{@port} (aggregation=#{@aggregation})"
        start_aggregation_thread if aggregation_enabled?

        begin
          Socket.udp_server_loop_on(sockets) do |msg, _|
            Rails.logger.debug "[ActiveStatsD] UDP packet received: #{msg.strip}"
            handle_message(msg.strip)
          end
        rescue => e
          Rails.logger.error "[ActiveStatsD] Server error: #{e.class.name} - #{e.message}\n#{e.backtrace.join("\n")}"
        ensure
          sockets.each(&:close)
          @running = false
        end
      end
    end

    private

    def handle_message(message)
      metric, value, type = parse_metric(message)
      return unless metric && %w[c g ms].include?(type)

      @mutex.synchronize { @counters[metric] += value } if aggregation_enabled?
      forward_message(message) if forwarding_enabled?
      log_message(metric, value, type) unless aggregation_enabled?
    end

    def parse_metric(message)
      metric_data, type = message.split("|")
      metric, value = metric_data.split(":")
      [metric, value.to_i, type]
    rescue
      Rails.logger.error "[ActiveStatsD] Failed to parse metric: #{message}"
      nil
    end

    def start_aggregation_thread
      Thread.new do
        loop do
          sleep 10
          flush_metrics
        end
      end
    end

    def flush_metrics
      snapshot = {}
      @mutex.synchronize do
        snapshot = @counters.dup
        @counters.clear
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
    rescue => e
      Rails.logger.error "[ActiveStatsD] Forwarding error: #{e.message}"
    end

    def log_message(metric, value, type)
      Rails.logger.info "[ActiveStatsD] Metric received (no aggregation) - #{metric}:#{value}|#{type}"
    end
  end
end
