# frozen_string_literal: true

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
end
