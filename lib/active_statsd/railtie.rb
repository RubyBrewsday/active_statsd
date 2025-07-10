# frozen_string_literal: true

require 'rails/railtie'

module ActiveStatsD
  # Railtie for ActiveStatsD to start the server and extend Rails.
  class Railtie < ::Rails::Railtie
    initializer 'active_statsd.configure' do
      ActiveSupport.on_load(:before_initialize) do
        # nothing here; we’ll pick up whatever the user set in initializers
      end
    end

    initializer 'active_statsd.start_server', after: :initialize_logger do
      ActiveSupport.on_load(:after_initialize) do
        # build the server with the full config object
        server = ActiveStatsD::Server.new(ActiveStatsD.configuration)
        server.start

        # (optional) keep a global reference so you can flush manually
        Rails.application.config.active_statsd_server = server
      end
    end

    initializer 'active_statsd.extend_rails' do
      Rails.extend ActiveStatsD::RailsIntegration
    end
  end
end
