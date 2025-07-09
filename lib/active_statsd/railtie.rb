# lib/active_statsd/railtie.rb
require 'rails'

module ActiveStatsD
  class Railtie < Rails::Railtie
    initializer 'active_statsd.start_server' do
      ActiveSupport.on_load(:after_initialize) do
        server = ActiveStatsD::Server.new(
          host: ActiveStatsD.configuration.host,
          port: ActiveStatsD.configuration.port
        )

        server.start

        Rails.logger.info "[ActiveStatsD] Embedded StatsD server started on #{ActiveStatsD.configuration.host}:#{ActiveStatsD.configuration.port}"
      end
    end

    initializer 'active_statsd.extend_rails' do
      ActiveSupport.on_load(:after_initialize) do
        Rails.extend ActiveStatsD::RailsIntegration
      end
    end
  end
end
