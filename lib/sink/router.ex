defmodule Sink.Router do
  @moduledoc """
    A module show casing a example plug router

    Json choice:
    Decision was made to try and keep things as performant as possible by using Glazer for json.
    decided to use :use_nil so that null from json comes in as :null, and not nil.

  """
  use Plug.Router
  require Logger

  # Here we expose the PromEx handler for /metrics so that metric data can be fetched.
  plug PromEx.Plug, prom_ex_module: Sink.PromEx
  plug Plug.Logger
  plug :match

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    # json_decoder: Jason
    json_decoder: {:glazer_json, :decode, [[:use_nil]]}

  plug :dispatch

  get "/", do: Sink.Controller.Home.call(conn)

  post "/api/v1/echo" do
    # send_resp(conn, 200, Jason.encode!(conn.body_params))
    body = :glazer_json.encode_to_iodata!(%{"status" => "ok", "value" => 42})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end

  get "/api/v1/time" do
    Sink.Controller.Api.ServerTime.call(conn)
  end

  # TODO: How do we get query string bits into handlers?
  # TODO: How do we write our own liveView impl?
  # TODO: Short form function calling with plug get/post?

  get "/time" do
    Sink.Controller.ServerTime.call(conn)
  end

  get "items" do
    Sink.Controller.Items.call(conn)
  end

  # NOTE: Silly little proxy example
  # match _ do
  #   Logger.info("CONN #{inspect(conn.params)}")

  #   q = Map.get(conn.params, "q")

  #   # TODO: what method
  #   # TODO: what schema
  #   # {:ok, response} = Req.get("https://www.bbc.co.uk/")
  #   {:ok, response} = Req.get(q)

  #   Logger.info("Response Headers #{inspect(response.headers)}}")

  #   conn
  #   |> Kernel.then(fn conn ->
  #     Enum.reduce(
  #       response.headers,
  #       conn,
  #       fn {header_key, header_values}, conn ->
  #         # Logger.info("Header Key #{inspect(header_key)} Header Value #{inspect(header_value)}")
  #         # put_resp_header(conn, header_key, header_value)

  #         Enum.reduce(header_values, conn, fn hv, conn ->
  #           put_resp_header(conn, header_key, hv)
  #         end)
  #       end
  #     )
  #   end)
  #   |> send_resp(response.status, response.body)
  # end

  match _ do
    send_resp(conn, 404, "Missing")
  end
end
