defmodule Sink.View.Shared.Menu do
  def menu() do
    EEx.eval_string(
      Sink.View.Read.shared_read("menu"),
      []
    )
  end
end
