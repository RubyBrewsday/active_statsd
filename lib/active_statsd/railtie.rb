# frozen_string_literal: true

# lib/active_statsd/railtie.rb
require 'rails'

module ActiveStatsD
  # Railtie for ActiveStatsD to start the server and extend Rails.
  class Railtie < Rails::Railtie
    initializer 'active_statsd.start_server' do
      ActiveSupport.on_load(:after_initialize) do
        server = ActiveStatsD::Server.new(ActiveStatsD.configuration)
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
