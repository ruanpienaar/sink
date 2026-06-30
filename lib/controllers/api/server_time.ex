defmodule Sink.Controller.Api.ServerTime do
  import Plug.Conn
  # require Logger

  def call(conn) do
    {:ok, dt} = Sink.ServerTime.now()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, DateTime.to_string(dt))
  end
end
