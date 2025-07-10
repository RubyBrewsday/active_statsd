# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveStatsD::Server do
  let(:config) do
    config = ActiveStatsD::Configuration.new
    config.host = '127.0.0.1'
    config.port = 9125
    config.aggregation = true
    config.forward_host = nil
    config.forward_port = nil
    config.flush_interval = 10
    config
  end

  let(:server) { described_class.new(config) }

  before { allow(Rails.logger).to receive(:info) }

  describe '#start' do
    it 'starts UDP server without errors' do
      expect { server.start }.not_to raise_error
    end
  end

  describe '#stop' do
    it 'sets shutdown flag and flushes metrics' do
      server.start
      expect(server).to receive(:flush_metrics)
      server.stop
      shutdown_flag = server.instance_variable_get(:@shutdown)
      expect(shutdown_flag.true?).to be(true)
    end
  end

  describe '#handle_message' do
    it 'aggregates counter metrics correctly' do
      server.send(:handle_message, 'test.metric:1|c')
      counters = server.instance_variable_get(:@counters)
      expect(counters['test.metric'].value).to eq(1)
    end

    it 'handles invalid metrics gracefully' do
      expect(Rails.logger).to receive(:error).with(/Failed to parse/)
      server.send(:handle_message, 'bad_metric')
    end
  end
end
