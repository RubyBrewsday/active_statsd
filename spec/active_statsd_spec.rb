# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveStatsD do
  it 'has a version number' do
    expect(ActiveStatsD::VERSION).not_to be nil
  end

  it 'can configure the gem properly' do
    ActiveStatsD.configure do |config|
      config.host = 'localhost'
      config.port = 1234
      config.namespace = 'test_app'
    end

    expect(ActiveStatsD.configuration.host).to eq('localhost')
    expect(ActiveStatsD.configuration.port).to eq(1234)
    expect(ActiveStatsD.configuration.namespace).to eq('test_app')
  end
end
