defmodule Lobbyserver.DiscordBackend do
  use Nostrum.Consumer

  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content do
      "!ping" ->
        m = Api.create_message!(msg.channel_id, "pong")
        Process.sleep(2_000);
        Nostrum.Api.delete_message!(msg);
        Nostrum.Api.delete_message!(m);
      "!get lobbies" ->
        lobbies = 
          "There are " <> Integer.to_string(:ets.info(ConCache.ets(:lobbies), :size)) <> " servers:\n```\n" 
          <> "ID\t\t\t\t\t| IP\n"
          <> :ets.foldl(fn ({id, val}, acc) -> 
              val["id"] 
              <> "\t  " 
              <> val["metadata"]["ip"] <> ":" <> val["metadata"]["port"]
              <> "\n" 
              <> acc 
            end, "", ConCache.ets(:lobbies))
          <> "\n```"
        bot_message = Api.create_message!(msg.channel_id, lobbies)
        Process.sleep(10_000);
        Nostrum.Api.delete_message!(msg);
        Nostrum.Api.delete_message!(bot_message);
      _ ->
        :ignore
    end
  end

  def handle_event(_event) do
    :noop
  end
end