defmodule Sink.Router do
  @moduledoc """
    A module show casing a example plug router

    Json choice:
    Decision was made to try and keep things as performant as possible by using Glazer for json.
    decided to use :use_nil so that null from json comes in as :null, and not nil.

  """
  use Plug.Router
  use Plug.ErrorHandler
  require Logger

  # Here we expose the PromEx handler for /metrics so that metric data can be fetched.
  plug PromEx.Plug, prom_ex_module: Sink.PromEx
  plug Plug.Logger
  plug Sink.Plug.Tempo
  # plug Sink.Plug.RequestSpan
  plug :match

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    # json_decoder: Jason
    json_decoder: {:glazer_json, :decode, [[:use_nil]]}

  plug :dispatch

  # TODO: How do we get query string bits into handlers?
  # TODO: How do we write our own liveView impl?
  # TODO: url query string? how can we do path placeholders, like /api/v1/:what/new
  # TODO: How can we dynamically add/remove/edit routes?
  # TODO: How do we do websockets?
  # TODO: how can we add telemetry to call durations and errors?

  # get "/", do: Sink.Controller.Home.call(conn)
  get "/", do: Sink.Plug.DispatchSpan.call(Sink.Controller.Home, conn)
  post "/api/v1/echo", do: Sink.Controllers.Api.Echo.call(conn)
  get "/api/v1/time", do: Sink.Controller.Api.ServerTime.call(conn)
  get "/time", do: Sink.Controller.ServerTime.call(conn)
  get "/items", do: Sink.Controller.Items.call(conn)
  post "/new/user/:name", do: Sink.Plug.DispatchSpan.call(Sink.Controller.Create.User, conn)
  match _, do: send_resp(conn, 404, "Missing")

  defp handle_errors(conn, _o = %{kind: kind, reason: _reason, stack: _stack}) do
    # Logger.error(o)

    :ok =
      :telemetry.execute(
        [:sink, :failed, :plug_requests],
        %{},
        %{kind: kind}
      )

    send_resp(conn, conn.status, "Something went wrong")
  end
end
