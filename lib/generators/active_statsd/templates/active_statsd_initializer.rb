# frozen_string_literal: true

ActiveStatsD.configure do |config|
  config.host = '127.0.0.1'
  config.port = 8125
  config.namespace = Rails.application.class.module_parent_name.underscore
  config.aggregation = true
  config.forward_host = nil
  config.forward_port = nil
  config.flush_interval = 10
end
