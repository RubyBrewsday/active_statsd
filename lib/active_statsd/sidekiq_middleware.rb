# frozen_string_literal: true

# lib/active_statsd/sidekiq_middleware.rb
module ActiveStatsD
  # Sidekiq middleware for ActiveStatsD.
  class SidekiqMiddleware
    def call(worker, _job, _queue, &block)
      Rails.stats.timing("sidekiq.#{worker.class.name.underscore}.perform", &block)
      Rails.stats.increment('sidekiq.jobs.processed', tags: { worker: worker.class.name })
    rescue StandardError => e
      Rails.stats.increment('sidekiq.jobs.failed', tags: { worker: worker.class.name })
      raise e
    end
  end
end
