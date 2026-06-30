defmodule Sink.View.Read do
  # Read metric?

  # How can we store the already READ file in ETS or p-term.
  # And create a file system checker, if html file changed upload ETS or p-term

  def read(name) when is_binary(name) do
    # TODO: get cwd of module?
    {:ok, data} = File.read("lib/view/" <> name <> ".ex.html")
    data
  end

  def shared_read(name) when is_binary(name) do
    # TODO: get cwd of module?
    {:ok, data} = File.read("lib/view/shared/" <> name <> ".ex.html")
    data
  end
end
