defmodule Sink.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link(
      [
        {Tz.UpdatePeriodically, []},
        Sink.PromEx,
        # {Bandit, plug: Sink.HelloWorld, port: 4000}
        {Bandit, plug: Sink.Router, port: 4000}
      ],
      strategy: :one_for_one,
      name: __MODULE__
    )
  end
end
