# frozen_string_literal: true

require 'spec_helper'
require 'active_statsd/sidekiq_middleware'

RSpec.describe ActiveStatsD::SidekiqMiddleware do
  let(:worker) { double('Worker', class: double(name: 'TestWorker')) }
  let(:job) { {} }
  let(:queue) { 'default' }

  it 'reports successful job metrics' do
    expect(Rails.stats).to receive(:timing).with('sidekiq.test_worker.perform')
    expect(Rails.stats).to receive(:increment).with('sidekiq.jobs.processed', tags: { worker: 'TestWorker' })

    described_class.new.call(worker, job, queue) { true }
  end

  it 'reports failed job metrics' do
    expect(Rails.stats).to receive(:increment).with('sidekiq.jobs.failed', tags: { worker: 'TestWorker' })
    expect do
      described_class.new.call(worker, job, queue) { raise 'error' }
    end.to raise_error('error')
  end
end
