defmodule Sink.PromEx.Plugins.PlugRequests do
  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    Event.build(
      :sink_plug_request_metrics,
      [
        counter(
          "sink.failed.plug_request",
          event_name: [:sink, :failed, :plug_requests],
          description: "Total number of plug requests",
          tags: [:status],
          tag_values: fn %{status: status} -> %{status: status} end
        ),
        distribution(
          "sink.plug_request.process.stop.duration",
          event_name: [:sink, :plug_request, :process, :stop],
          measurement: :duration,
          unit: {:native, :millisecond},
          reporter_options: [buckets: [1, 5, 10, 50, 250, 1_000, 4_000, 10_000, 30_000]]
        )
      ]
    )
  end
end
