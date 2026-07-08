defmodule Sink.Application do
  use Application

  def start(_type, _args) do
    :ok = Sink.Ets.init_all()

    Supervisor.start_link(
      [
        {Tz.UpdatePeriodically, []},
        Sink.PromEx,
        # IPv4-only is intentional, not an oversight - see README.md
        # ("Network exposure / WAF") for why that's safe here.
        {Bandit, plug: Sink.Router, port: 4000, ip: {0, 0, 0, 0}}
      ],
      strategy: :one_for_one,
      name: __MODULE__
    )
  end
end
