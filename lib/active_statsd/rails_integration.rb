# frozen_string_literal: true

# lib/active_statsd/rails_integration.rb
module ActiveStatsD
  # Rails integration module providing stats access.
  module RailsIntegration
    def stats
      ActiveStatsD.client
    end
  end
end
