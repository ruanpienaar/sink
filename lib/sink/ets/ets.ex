defmodule Sink.Ets do
  @callback init() :: atom()
  @callback name() :: atom()
  @callback insert(record :: tuple()) :: :ok
  @callback lookup(key :: term()) :: term()

  # tuple spec as a callback?

  def init_all() do
    Enum.each([Sink.Ets.Client.ConnInfo], fn m -> _name = m.init() end)
  end
end
