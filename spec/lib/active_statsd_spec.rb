# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveStatsD do
  it 'has a version number' do
    expect(ActiveStatsD::VERSION).not_to be_nil
  end

  it 'can configure the gem properly' do
    described_class.configure do |config|
      config.host = 'localhost'
      config.port = 1234
      config.namespace = 'test_app'
    end

    expect(described_class.configuration.host).to eq('localhost')
    expect(described_class.configuration.port).to eq(1234)
    expect(described_class.configuration.namespace).to eq('test_app')
  end
end
