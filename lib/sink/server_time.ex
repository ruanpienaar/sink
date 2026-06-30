defmodule Sink.ServerTime do
  def now() do
    Tz.TimeZoneDatabase = Calendar.get_time_zone_database()

    case Application.get_env(:sink, :timezone) do
      nil ->
        DateTime.now("Etc/UTC")

      timezone when is_binary(timezone) ->
        DateTime.now(timezone, Tz.TimeZoneDatabase)
    end
  end
end
