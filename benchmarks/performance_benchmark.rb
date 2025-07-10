# frozen_string_literal: true

require 'benchmark/ips'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'active_statsd'
require 'active_support/testing/time_helpers'
require 'active_support/isolated_execution_state'

client = ActiveStatsD::Client.new(
  host: '127.0.0.1',
  port: 8125,
  namespace: 'benchmark'
)

socket = UDPSocket.new
client.instance_variable_set(:@socket, socket)

Benchmark.ips do |x|
  x.config(time: 10, warmup: 5)

  x.report('increment counter')    { client.increment('perf.test.counter') }
  x.report('gauge metric')         { client.gauge('perf.test.gauge', rand(1000)) }
  x.report('timing metric')        { client.timing('perf.test.timing') { sleep(0.001) } }

  x.compare!
end
