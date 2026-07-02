defmodule Sink.Controller.Create.User do
  import Plug.Conn
  require Logger

  def call(conn) do
    # The :name parameter will also be available in the function body as conn.params["name"] and conn.path_params["name"].
    Logger.notice("New user #{inspect(conn.path_params["name"])}")
    Logger.notice("New user #{inspect(conn.body_params)}")

    # Logger.notice("Request URL was #{inspect(request_url(conn))}")

    conn
    |> send_resp(200, "ok")
  end
end
