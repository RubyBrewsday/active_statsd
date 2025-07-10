# frozen_string_literal: true

# lib/active_statsd/railtie.rb
require 'rails'

module ActiveStatsD
  # Railtie for ActiveStatsD to start the server and extend Rails.
  class Railtie < Rails::Railtie
    initializer 'active_statsd.start_server' do
      ActiveSupport.on_load(:after_initialize) do
        server = ActiveStatsD::Server.new(
          host: ActiveStatsD.configuration.host,
          port: ActiveStatsD.configuration.port,
          aggregation: ActiveStatsD.configuration.aggregation,
          forward_host: ActiveStatsD.configuration.forward_host,
          forward_port: ActiveStatsD.configuration.forward_port
        )
        server.start
      end
    end

    initializer 'active_statsd.extend_rails' do
      ActiveSupport.on_load(:after_initialize) do
        Rails.extend ActiveStatsD::RailsIntegration
      end
    end
  end
end
