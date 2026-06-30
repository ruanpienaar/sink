import Config

config :sink, Sink.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :sink, timezone: "Europe/London"
