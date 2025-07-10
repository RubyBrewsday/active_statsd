# frozen_string_literal: true

# lib/generators/active_statsd/active_statsd_generator.rb
require 'rails/generators'

module ActiveStatsD
  class ActiveStatsDGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def copy_initializer_file
      copy_file 'active_statsd_initializer.rb', 'config/initializers/active_statsd.rb'
    end
  end
end
