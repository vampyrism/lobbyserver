defmodule LobbyserverWeb.Api.LobbyController do
  use LobbyserverWeb, :controller

  defp get_ip(conn) do
    forwarded_for = List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))
  
    if forwarded_for do
      String.split(forwarded_for, ",")
      |> Enum.map(&String.trim/1)
      |> List.first()
    else
      to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end

  defp discord_api_post_request(url, data) do
    token = Application.get_env(:lobbyserver, Discord)[:token]
    application_id = Application.get_env(:lobbyserver, Discord)[:client_id]
    headers = [{"Content-Type", "application/json"}, {"Authorization", "Bot " <> token}]
    params = Poison.encode!(Map.merge(data, %{"application_id" => Application.get_env(:lobbyserver, Discord)[:client_id]}))

    case HTTPoison.post(url, params, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body)}
      e ->
        IO.inspect(e)
        IO.puts("Something went wrong during discord api post request")
        {:error, "Something went wrong during discord api post request"}
    end
  end

  defp create_lobby(conn, port) do
    url = "https://discord.com/api/v6/lobbies"
    lobby_data = %{
      "id" => UUID.uuid1(:hex) |> String.slice(0..15),
      "secret" => UUID.uuid1(:hex) |> String.slice(0..15),
      "type" => 1,
      "capacity" => 150,
      "region" => "eu_sto",
      "metadata" => 
        %{
          "status" => "in_lobby", 
          "server_version" => "0.0.1", 
          "ip" => get_ip(conn) |> String.slice(7..-1), 
          "port" => port
        }
    }

    # {:ok, lobby_data} = discord_api_post_request(url, data)
    
    channel_id = Nostrum.Snowflake.cast!(Application.get_env(:lobbyserver, Discord)[:channel_id])

    Nostrum.Api.create_message(channel_id,
      content: "A server has been found...*spoopy*.\n```\nLobby ID\t\t" <> lobby_data["id"] 
        <> "\nIP\t\t\t  " <> (get_ip(conn) |> String.slice(7..-1))
        <> "\nPort\t\t\t" <> port
        <> "\nPlayers\t\t 0/" <> Integer.to_string(lobby_data["capacity"]) 
        <> "\nRegion\t\t  " <> lobby_data["region"] <> "\n```"
        <> "\nDebugging info\n```json\n"
        <> Poison.encode!(lobby_data) <> "\n```\n")

    ConCache.put(:lobbies, lobby_data["id"], lobby_data)

    {:ok, lobby_data}
  end

  def get_by_id(conn, %{"id" => id} = _params) do
    json(conn, ConCache.get(:lobbies, id))
  end

  def new(conn, %{"port" => port} = _params) do
    case create_lobby(conn, port) do
      {:ok, lobby} ->
        json(conn, lobby)
      {:error, reason} ->
        json(conn, %{"error" => reason})
    end
  end

  def new(conn, params) do
    new(conn, %{params | "port" => 9000})
  end

  def heartbeat(conn, %{"id" => id} = _params) do
    case ConCache.get(:lobbies, id) do
      nil ->
        text(conn, "not ok")
      _ ->
        text(conn, "ok")
    end
  end
end