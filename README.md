# ActiveStatsD

ActiveStatsD is a lightweight Ruby gem providing a built-in StatsD-compatible UDP server and client integration directly within your Rails applications. It simplifies local metrics aggregation during development and seamlessly integrates with external aggregation services like Datadog in production.

---

## Installation

Add this line to your Rails application's Gemfile:

```ruby
gem 'active_statsd'
```

Then execute:

```bash
bundle install
rails generate active_stats_d:active_stats_d
```

Create an initializer manually at `config/initializers/active_statsd.rb`:

```ruby
# config/initializers/active_statsd.rb
ActiveStatsD.configure do |config|
  config.host = '127.0.0.1'
  config.port = 8125
  config.namespace = 'my_rails_app'
  config.aggregation = true        # local aggregation (default: true)
  config.forward_host = nil        # set if forwarding metrics externally
  config.forward_port = nil
end
```

---

## Usage

### Sending Metrics

Use the convenient `Rails.stats` interface:

```ruby
# Increment a counter
Rails.stats.increment('user.signup.success')

# Record a gauge metric
Rails.stats.gauge('user.current.active_sessions', 123)

# Measure execution time
Rails.stats.timing('db.query.time') do
  User.where(active: true).load
end
```

---

## Development Mode (Embedded Server)

In development mode, ActiveStatsD automatically runs an embedded UDP StatsD server to locally aggregate metrics. Aggregated metrics are flushed to your Rails logs every 10 seconds:

```
[ActiveStatsD] Aggregated metric - my_rails_app.user.signup.success: 42
```

If aggregation is disabled (`aggregation: false`), each metric is logged immediately:

```
[ActiveStatsD] Metric received (no aggregation) - my_rails_app.user.signup.success:1|c
```

---

## Sidekiq Integration (Optional)

To automatically track Sidekiq metrics, add this middleware explicitly:

````ruby
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ActiveStatsD::SidekiqMiddleware
  end
end

---

## Production Usage & Datadog Integration

For multi-server setups, disable the local aggregation and forward metrics directly to a centralized aggregator like Datadog:

```ruby
# config/environments/production.rb
ActiveStatsD.configure do |config|
  config.aggregation = false
  config.forward_host = ENV['DATADOG_AGENT_HOST'] || 'datadog-agent.internal'
  config.forward_port = 8125
  config.namespace = 'my_rails_app'
end
````

### Datadog Setup

1. **Install Datadog agent:** [Official Datadog Installation Docs](https://docs.datadoghq.com/agent/)
2. **Configure Rails app:** Ensure metrics forward to Datadog agent as shown above.
3. **View metrics:** Datadog will aggregate and provide centralized dashboards automatically.

No additional code is needed; ActiveStatsD metrics are fully compatible with Datadog.

---

## Development

After cloning the repository, run:

```bash
bin/setup
```

To run tests:

```bash
bundle exec rake spec
```

To experiment with the gem interactively:

```bash
bin/console
```

### Releasing a New Version

Update the version in `lib/active_statsd/version.rb`, then run:

```bash
bundle exec rake release
```

This tags the release, pushes commits and tags, and publishes to [RubyGems](https://rubygems.org).

---

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/RubyBrewsday/active_statsd](https://github.com/RubyBrewsday/active_statsd).

This project is intended to be a welcoming space for collaboration. Contributors must adhere to the [Code of Conduct](https://github.com/RubyBrewsday/active_statsd/blob/main/CODE_OF_CONDUCT.md).

---

## License

The gem is open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

## Code of Conduct

All interactions in ActiveStatsD's codebase, issue tracker, chat rooms, and mailing lists are governed by the [Code of Conduct](https://github.com/RubyBrewsday/active_statsd/blob/main/CODE_OF_CONDUCT.md).
