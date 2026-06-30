defmodule Sink.HelloWorld do
  @moduledoc """
      Tiny example showcasing how you could write module plug and start it supervised as:
      ```Elixir
        Supervisor.start_link(
        [{Bandit, plug: Sink.HelloWorld, port: 4000}],
        strategy: :one_for_one,
        name: __MODULE__
      )
      ```
  """

  # @behaviour Plug
  # import Plug.Conn

  # @impl true
  # def init(opts), do: opts

  # @impl true
  # def call(conn, _opts) do
  #   conn
  #   |> put_resp_content_type("text/plain")
  #   |> send_resp(200, "Hello, World!")
  # end
end
