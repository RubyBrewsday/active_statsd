# lib/active_statsd/rails_integration.rb
module ActiveStatsD
  module RailsIntegration
    def stats
      ActiveStatsD.client
    end
  end
end
