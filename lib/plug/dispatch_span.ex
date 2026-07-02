defmodule Sink.Plug.DispatchSpan do
  def call(module, conn) do
    # TODO get route from conn, or use something that's less dynamic, as it might create high cardinality

    :telemetry.span(
      [:sink, :plug_request, :process],
      %{route: "/"},
      fn ->
        result = module.call(conn)
        # second element merges into :stop metadata
        {result, %{status: :ok}}
      end
    )
  end
end
