require 'spec_helper'

RSpec.describe ActiveStatsD::Server do
  let(:server) do
    described_class.new(
      host: '127.0.0.1',
      port: 9125,
      aggregation: true,
      forward_host: nil,
      forward_port: nil
    )
  end

  before { allow(Rails.logger).to receive(:info) }

  describe '#start' do
    it 'starts UDP server without errors' do
      expect { server.start }.not_to raise_error
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
