# frozen_string_literal: true

ActiveStatsD.configure do |config|
  config.host = '127.0.0.1'
  config.port = 8125
  config.namespace = 'my_rails_app'
end
