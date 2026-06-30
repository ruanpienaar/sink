defmodule Sink.Controller.Home do
  import Plug.Conn

  def call(conn) do
    # TODO: EEx eval_string time? timer.tc?

    conn
    |> send_resp(
      200,
      EEx.eval_string(
        Sink.View.Read.read("home"),
        title: "Home",
        menu: Sink.View.Shared.Menu.menu()
      )
    )
  end
end
