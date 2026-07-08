defmodule Sink.Plug.Tempo do
  @moduledoc """
  Per-client request rate limiting.

  ## Network exposure

  This app binds IPv4 only (see `lib/sink/applicaiton.ex`) and expects to
  sit behind a WAF/CDN or load balancer that terminates the actual
  internet-facing connection - IPv6 included - and does its own
  rate-limiting/abuse detection at the edge. See README.md ("Network
  exposure") for the reasoning.

  ## Trusted proxies

  Because of that, `conn.remote_ip` is the proxy's address, not the real
  client's - the real client address (if any) is carried in the
  `Forwarded`/`X-Forwarded-For` request headers instead. Those headers are
  attacker-supplied and trivially spoofable, so they are only trusted when
  the request actually arrived from a configured proxy address - see
  `:sink, :trusted_proxies` (config/config.exs, overridable per
  deployment via the `TRUSTED_PROXY_IPS` env var - see
  config/runtime.exs). If no trusted proxies are configured, or the
  immediate peer isn't one of them, `conn.remote_ip` is used as-is and the
  forwarding headers are ignored entirely.
  """
  require Logger
  import Plug.Conn
  @behaviour Plug

  @impl true
  def init(opts) do
    opts
  end

  @impl true
  def call(conn, _opts) do
    # Enum.map(conn, fn k, v -> Logger.notice("#{inspect(k)} : #{inspect(v)}") end)
    #   %Plug.Conn{
    #   adapter: {Bandit.Adapter, :...},
    #   assigns: %{},
    #   body_params: %Plug.Conn.Unfetched{aspect: :body_params},
    #   cookies: %Plug.Conn.Unfetched{aspect: :cookies},
    #   halted: false,
    #   host: "172.20.7.170",
    #   method: "POST",
    #   owner: nil,
    #   params: %Plug.Conn.Unfetched{aspect: :params},
    #   path_info: ["new", "user", "ruan"],
    #   path_params: %{},
    #   port: 4000,
    #   private: %{before_send: [#Function<1.8684523/1 in Plug.Logger.call/2>]},
    #   query_params: %Plug.Conn.Unfetched{aspect: :query_params},
    #   query_string: "",
    #   remote_ip: {172, 20, 3, 24},
    #   req_cookies: %Plug.Conn.Unfetched{aspect: :cookies},
    #   req_headers: [
    #     {"host", "172.20.7.170:4000"},
    #     {"user-agent", "curl/8.18.0"},
    #     {"accept", "*/*"},
    #     {"content-type", "application/json"},
    #     {"content-length", "13"}
    #   ],
    #   request_path: "/new/user/ruan",
    #   resp_body: nil,
    #   resp_cookies: %{},
    #   resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"}],
    #   scheme: :http,
    #   script_name: [],
    #   secret_key_base: nil,
    #   state: :unset,
    #   status: nil
    # }
    # Logger.notice("#{inspect(conn)}")

    # TODO: where are we starting tempo. Surely having all network requests bottle necked into one is massive. And having each connecting start a tempo, is equally massive? or is it?
    # TODO:   ^^^ it currently starts with ARG-1 as a atom, that seems counter productive with the data we're using to start, like, IP-PORT, user-agent etc.

    client_ip = client_ip(conn)

    IO.inspect(client_ip, label: "Sink.Plug.Tempo client_ip")

    case Sink.Ets.Client.ConnInfo.lookup(client_ip) do
      nil ->
        reference = :erlang.make_ref()

        {:ok, tempo_pid} =
          :tempo.start(
            reference,
            Application.get_env(:sink, :max_requests),
            Application.get_env(:sink, :max_requests_timeframe_ms)
          )

        :ok = Sink.Ets.Client.ConnInfo.insert({client_ip, reference, tempo_pid})
        conn

      [{^client_ip, _ref, tempo_pid}] ->
        # IO.inspect(tempo_pid, label: "tempo_pid")
        # IO.inspect(:erlang.process_info(tempo_pid), label: "tempo_pid info")
        can_make = :tempo.can_make_call(tempo_pid)
        IO.inspect(can_make, label: "can_make_request")

        if can_make == true do
          conn
        else
          conn |> send_resp(429, "") |> halt()
        end
    end
  end

  @doc """
  The address that should be rate-limited for this request - the real
  client's address if it can be established from a trusted proxy,
  otherwise `conn.remote_ip` directly.
  """
  @spec client_ip(Plug.Conn.t()) :: :inet.ip_address()
  defp client_ip(conn) do
    trusted_proxies = Application.get_env(:sink, :trusted_proxies, [])

    if conn.remote_ip in trusted_proxies do
      forwarded_client_ip(conn, trusted_proxies) || conn.remote_ip
    else
      conn.remote_ip
    end
  end

  # Forwarding headers list hops left (original client) to right (most
  # recent proxy). Walk right-to-left, skipping addresses that are
  # themselves trusted proxies - the first one that isn't is the address
  # the nearest trusted hop says it received the connection from.
  defp forwarded_client_ip(conn, trusted_proxies) do
    ips =
      case get_req_header(conn, "forwarded") do
        [] ->
          conn |> get_req_header("x-forwarded-for") |> Enum.join(",") |> parse_x_forwarded_for()

        values ->
          values |> Enum.join(",") |> parse_forwarded()
      end

    ips
    |> Enum.reverse()
    |> Enum.find(fn ip -> ip not in trusted_proxies end)
  end

  defp parse_x_forwarded_for(value) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(&parse_ip/1)
  end

  # RFC 7239: comma-separated hops, each a `;`-separated list of
  # `key=value` pairs - we only care about the `for=` param, which may be
  # quoted and, for IPv6, bracketed with an optional port
  # (`for="[2001:db8::1]:4711"`).
  defp parse_forwarded(value) do
    value
    |> String.split(",")
    |> Enum.map(&for_param/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.flat_map(&parse_ip/1)
  end

  defp for_param(hop) do
    hop
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.find_value(fn pair ->
      case String.split(pair, "=", parts: 2) do
        [key, value] -> if String.downcase(key) == "for", do: strip_for_value(value)
        _ -> nil
      end
    end)
  end

  defp strip_for_value(value) do
    stripped = value |> String.trim() |> String.trim("\"") |> String.trim_leading("[")

    cond do
      stripped == "" -> stripped
      String.contains?(stripped, "]") -> stripped |> String.split("]") |> List.first()
      String.contains?(stripped, ":") -> stripped |> String.split(":") |> List.first()
      true -> stripped
    end
  end

  defp parse_ip(string) do
    case :inet.parse_address(String.to_charlist(string)) do
      {:ok, ip} -> [ip]
      {:error, _reason} -> []
    end
  end
end
