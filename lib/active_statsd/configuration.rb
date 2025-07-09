module ActiveStatsD
  class Configuration
    attr_accessor :host, :port, :namespace

    def initialize
      @host = '127.0.0.1'
      @port = 8125
      @namespace = 'rails_app'
    end
  end
end
