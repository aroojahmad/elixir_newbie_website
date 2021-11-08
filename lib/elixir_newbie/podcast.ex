defmodule ElixirNewbie.Podcast do
  use GenServer

  alias ElixirNewbie.PodcastAPI

  @hydrate_interval 1000 * 60 * 5

  def get(server \\ __MODULE__) do
    GenServer.call(server, {:get})
  end

  def start_link(opts) do
    server_name = Access.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: server_name)
  end

  def init(_args) do
    :timer.send_interval(@hydrate_interval, self(), :hydrate)
    {:ok, %{episodes: PodcastAPI.get()}}
  end

  def handle_call({:get}, _from, state) do
    {:reply, state.episodes, state}
  end

  def handle_info(:hydrate, state) do
    episodes =
      try do
        PodcastAPI.get()
      rescue
        RuntimeError -> state.episodes
      end

    if state.episodes == episodes do
      {:noreply, state}
    else
      Phoenix.PubSub.broadcast(
        ElixirNewbie.PubSub,
        "update episodes",
        {:update_episodes, episodes}
      )

      {:noreply, %{state | episodes: episodes}}
    end
  end
end
