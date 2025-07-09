# ActiveStatsD

ActiveStatsD is a lightweight Ruby gem that provides a built-in StatsD-compatible UDP server and client integration directly within your Rails applications. It simplifies local metrics aggregation during development and seamlessly integrates with external aggregation services like Datadog in production.

---

## Installation

Add this line to your Rails application's Gemfile:

```ruby
gem 'active_statsd'
```

And then execute:

```bash
bundle install
```

---

## Usage

### Configuration

Configure ActiveStatsD in your Rails initializer:

```ruby
# config/initializers/active_statsd.rb
ActiveStatsD.configure do |config|
  config.host = '127.0.0.1'
  config.port = 8125
  config.namespace = 'my_rails_app'
end
```

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

---

## Production Usage

For multi-server production setups, it's recommended to disable the embedded server and instead send metrics directly to a centralized aggregator like Datadog:

```ruby
# config/environments/production.rb
ActiveStatsD.configure do |config|
  config.host = ENV['DATADOG_AGENT_HOST'] || 'datadog-agent.internal'
  config.port = 8125
  config.namespace = 'my_rails_app'
end
```

Datadog will handle metric aggregation across multiple instances and provide centralized dashboards.

---

## Development

After cloning the repository, run `bin/setup` to install dependencies. To run tests:

```bash
bundle exec rake spec
```

To experiment with the gem interactively, use:

```bash
bin/console
```

To release a new version, update the version number in `lib/active_statsd/version.rb`, and run:

```bash
bundle exec rake release
```

This will tag the release, push commits and tags, and release to [RubyGems](https://rubygems.org).

---

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/RubyBrewsday/active_statsd](https://github.com/RubyBrewsday/active_statsd).

This project is intended to be a welcoming space for collaboration. Contributors are expected to adhere to the [Code of Conduct](https://github.com/RubyBrewsday/active_statsd/blob/main/CODE_OF_CONDUCT.md).

---

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

## Code of Conduct

Everyone interacting in ActiveStatsD's codebase, issue tracker, chat rooms, and mailing lists is expected to follow the [Code of Conduct](https://github.com/RubyBrewsday/active_statsd/blob/main/CODE_OF_CONDUCT.md).
