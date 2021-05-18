defmodule ExTda.Cache do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    cache = :ets.new(:code_cache, [:named_table])
    Process.sleep(100)
    {:ok, cache}
  end

  def cache() do
    GenServer.call(__MODULE__, :cache)
  end

  def handle_call(:cache, _from, cache) do
    {:reply, cache, cache}
  end
end
