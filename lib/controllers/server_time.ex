defmodule Sink.Controller.ServerTime do
  import Plug.Conn

  def call(conn) do
    {:ok, dt} = Sink.ServerTime.now()

    conn
    |> send_resp(
      200,
      EEx.eval_string(
        Sink.View.Read.read("server_time"),
        title: "Server Time",
        server_time_now: dt,
        menu: Sink.View.Shared.Menu.menu()
      )
    )
  end
end
