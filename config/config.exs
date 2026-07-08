import Config

config :sink, Sink.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :sink, timezone: "Europe/London"

config :sink,
  max_requests: 1,
  max_requests_timeframe_ms: 5000

# Addresses of trusted reverse proxies/load balancers/WAFs, as
# `:inet.ip_address()` tuples. Only requests whose `remote_ip` matches one
# of these are allowed to supply a client address via the `Forwarded`/
# `X-Forwarded-For` headers - see Sink.Plug.Tempo.client_ip/1 and
# README.md ("Trusted proxies"). Overridable at runtime without a
# recompile via the TRUSTED_PROXY_IPS env var - see config/runtime.exs.
config :sink, trusted_proxies: []
