import Config

# Lets the WAF/LB address allowlist be set per-deployment without a
# recompile - e.g. TRUSTED_PROXY_IPS="203.0.113.5,203.0.113.6". Only
# evaluated when this app is booted as a Mix release; see
# config/config.exs for the compile-time default used otherwise (e.g.
# `iex -S mix`, `mix run`).
if trusted_proxy_ips = System.get_env("TRUSTED_PROXY_IPS") do
  trusted_proxies =
    trusted_proxy_ips
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn ip ->
      case :inet.parse_address(String.to_charlist(ip)) do
        {:ok, address} ->
          address

        {:error, _reason} ->
          raise "invalid IP address #{inspect(ip)} in TRUSTED_PROXY_IPS"
      end
    end)

  config :sink, trusted_proxies: trusted_proxies
end
