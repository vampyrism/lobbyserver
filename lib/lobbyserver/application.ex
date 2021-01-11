defmodule Lobbyserver.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LobbyserverWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lobbyserver.PubSub},
      # Start the Endpoint (http/https)
      LobbyserverWeb.Endpoint,
      # Start a worker by calling: Lobbyserver.Worker.start_link(arg)
      # {Lobbyserver.Worker, arg}

      # Initialize lobby database
      {ConCache, [
        name: :lobbies,
        ttl_check_interval: :timer.seconds(10),
        global_ttl: :timer.minutes(1), # Server needs to heartbeat at least 1/min
        touch_on_read: true
      ]},

      {Lobbyserver.InitDiscord, restart: :transient},
      Lobbyserver.DiscordBackend
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lobbyserver.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LobbyserverWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
