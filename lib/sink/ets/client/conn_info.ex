defmodule Sink.Ets.Client.ConnInfo do
  @behaviour Sink.Ets

  @name :client_conn_info
  @impl true
  def init() do
    _name = :ets.new(@name, [:named_table, :public, :set])
  end

  @impl true
  def name() do
    @name
  end

  @impl true
  def insert({client_ip, reference, tempo_pid}) do
    true = :ets.insert(@name, {client_ip, reference, tempo_pid})
    :ok
  end

  @impl true
  def lookup(key) do
    case :ets.lookup(@name, key) do
      [] ->
        nil

      entries when is_list(entries) ->
        entries
    end
  end
end
