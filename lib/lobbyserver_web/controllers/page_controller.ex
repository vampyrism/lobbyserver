defmodule LobbyserverWeb.PageController do
  use LobbyserverWeb, :controller

  def index(conn, _params) do
    lobbies = ConCache.ets(:lobbies)
    render(conn, "index.html", lobbies: lobbies)
  end
end
