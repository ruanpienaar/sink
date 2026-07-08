# Sink

Using Elixir Plug

## Network exposure

This app binds an IPv4-only listener (`lib/sink/applicaiton.ex`) and is
designed to run behind a WAF/CDN or load balancer, not directly on the
internet.

That's a deliberate choice, not an oversight. A WAF/CDN (Cloudflare, an
AWS ALB + WAF, Fastly, etc.) is the thing actually terminating
internet-facing connections, so it absorbs the abuse cases an
app-level rate limiter can't handle well on its own - in particular,
an attacker rotating through IPv6 addresses (trivial to do, since a
single delegation is usually a whole /64 or larger) to dodge a
per-client-IP rate limiter and, in the process, force this app to keep
allocating a new rate-limiter/ETS entry per address forever. A WAF
does that abuse detection at the edge, at a scale an Erlang
process-per-client scheme isn't built for, and this app then only ever
sees connections from the WAF's own small, fixed IPv4 egress range -
which is why hardcoding IPv4-only here is safe rather than limiting.

This does mean the WAF/CDN is a hard requirement, not an optional
extra: if this app is ever exposed directly to the internet without
one, IPv6-only clients simply can't connect at all, and there's no
edge-level abuse detection to fall back on.

## Trusted proxies

Because the WAF/LB sits in front, `conn.remote_ip` on every request is
the proxy's address, not the real client's - the real client address
(if any) is carried in the `Forwarded`/`X-Forwarded-For` headers
instead. Those headers are attacker-supplied and spoofable, so
`Sink.Plug.Tempo` only trusts them when `remote_ip` itself matches a
configured proxy address; otherwise `remote_ip` is used as-is and the
headers are ignored. See `Sink.Plug.Tempo.client_ip/1`.

Configure the allowlist of trusted WAF/LB addresses via
`config :sink, :trusted_proxies` (a list of `:inet.ip_address()`
tuples, defaults to `[]` in `config/config.exs`), or override it per
deployment without recompiling by setting `TRUSTED_PROXY_IPS` (a
comma-separated list of IPs) before booting a release - see
`config/runtime.exs`.
