defmodule Lobbyserver.InitDiscord do
  use GenServer, restart: :transient

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    Nostrum.Api.update_status(:dnd, "with their food", 0)

    # Process will send :timeout to self after 1 second
    {:ok, state, 1_000}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
end