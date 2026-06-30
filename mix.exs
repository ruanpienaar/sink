defmodule Sink.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sink,
      deps: deps(),
      version: "0.1.0"
    ]
  end

  def application do
    [
      mod: {Sink.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools
      ]
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.20"},
      {:bandit, "~> 1.12"},
      # {:jason, "~> 1.4"},
      {:glazer, "~> 0.5", manager: :rebar3},
      {:prom_ex, "~> 1.12"},
      {:tz, "~> 0.28"},
      {:req, "~> 0.6"}
    ]
  end
end
