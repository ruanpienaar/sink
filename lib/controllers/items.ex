defmodule Sink.Controller.Items do
  import Plug.Conn

  def call(conn) do
    items = %{
      item1: "Rock",
      item2: "Paper",
      item3: "Scissors"
    }

    conn
    |> send_resp(
      200,
      EEx.eval_string(
        Sink.View.Read.read("items"),
        title: "Items",
        items: items,
        menu: Sink.View.Shared.Menu.menu()
      )
    )
  end
end
