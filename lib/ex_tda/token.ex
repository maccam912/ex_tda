defmodule ExTda.Token do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(nil) do
    send(self(), :update)
    {:ok, nil}
  end

  @impl true
  def handle_info(:update, nil) do
    value = :ets.lookup(:kv, "refresh_token")

    if length(value) > 0 do
      new_token = ExTda.Client.get_access_token()
      :ets.insert(:kv, {"access_token", new_token})
    end

    Process.send_after(__MODULE__, :update, 1000 * 60 * 25)
    {:noreply, nil}
  end
end
