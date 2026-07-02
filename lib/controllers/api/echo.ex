defmodule Sink.Controllers.Api.Echo do
  import Plug.Conn

  def call(conn) do
    # send_resp(conn, 200, Jason.encode!(conn.body_params))
    body = :glazer_json.encode_to_iodata!(%{"status" => "ok", "value" => 42})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end
end
