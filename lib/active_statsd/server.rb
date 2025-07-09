# lib/active_statsd/server.rb
require 'socket'

module ActiveStatsD
  class Server
    def initialize(host: '127.0.0.1', port: 8125)
      @host = host
      @port = port
      @counters = Hash.new(0)
      @mutex = Mutex.new
    end

    def start
      start_aggregation_thread

      Thread.new do
        Rails.logger.info "[ActiveStatsD] UDP StatsD listener started on #{@host}:#{@port}"
        begin
          Socket.udp_server_loop(@host, @port) do |msg, _|
            Rails.logger.debug "[ActiveStatsD] UDP packet received: #{msg.strip}"
            handle_message(msg.strip)
          end
        rescue => e
          Rails.logger.error "[ActiveStatsD] Server error: #{e.class.name} - #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end
    end

    private

    def handle_message(message)
      metric, value, type = parse_metric(message)

      return unless metric && type == 'c'

      @mutex.synchronize do
        @counters[metric] += value
      end
    end

    def parse_metric(message)
      # Example message: "rails_app.test.metric:1|c"
      metric_data, type = message.split('|')
      metric, value = metric_data.split(':')

      [metric, value.to_i, type]
    rescue
      Rails.logger.error "[ActiveStatsD] Failed to parse metric: #{message}"
      nil
    end

    def start_aggregation_thread
      Thread.new do
        loop do
          sleep 10 # flush metrics every 10 seconds
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
  end
end
