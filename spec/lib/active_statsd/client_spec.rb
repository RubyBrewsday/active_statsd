# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveStatsD::Client do
  let(:socket) { instance_double(UDPSocket) }
  subject do
    described_class.new(host: '127.0.0.1', port: 9125, namespace: 'test')
  end

  before { allow(UDPSocket).to receive(:new).and_return(socket) }

  it 'increments a metric' do
    expect(socket).to receive(:send).with('test.counter:1|c', 0, '127.0.0.1', 9125)
    subject.increment('counter')
  end

  it 'sends gauge metrics' do
    expect(socket).to receive(:send).with('test.gauge:10|g', 0, '127.0.0.1', 9125)
    subject.gauge('gauge', 10)
  end

  it 'records timing metrics' do
    expect(socket).to receive(:send).with(/test.timing:\d+\|ms/, 0, '127.0.0.1', 9125)
    subject.timing('timing') { sleep(0.01) }
  end

  it 'increments metric with tags and sample_rate' do
    expect(socket).to receive(:send).with('test.counter:1|c|@0.5|#region:us-east', 0, '127.0.0.1', 9125)
    subject.increment('counter', tags: { region: 'us-east' }, sample_rate: 0.5)
  end
end
