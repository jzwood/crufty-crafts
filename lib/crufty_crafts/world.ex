defmodule Player do
  @moduledoc false
  @derive Jason.Encoder
  defstruct handle: nil,
            index: 0,
            boom: 0,
            lat: nil,
            long: nil,
            heading: 0,
            velocity: 0
end

defmodule Game do
  @moduledoc false
  @expire_seconds 60 * 60

  defstruct id: nil,
            host_secret: "",
            players: [],
            updated_at: 0

  def expire_seconds(), do: @expire_seconds

  def now(), do: :os.system_time(:second)

  def is_expired(%Game{updated_at: updated_at}) do
    updated_at + @expire_seconds < now()
  end

  def fetch_player(game, player_secret) do
    Map.fetch(game.players, player_secret)
  end

  def add_player(%Game{} = game, handle: handle, secret: secret) do
    index = Enum.count(game.players)

    Game.upsert_player(game, secret, %Player{
      handle: handle,
      lat: 0,
      long: 0,
      index: index
    })
  end

  def kick_player(%Game{players: players} = game, handle: handle) do
    players =
      players
      |> Enum.filter(fn {_secret, %Player{} = player} -> player.handle != handle end)
      |> Map.new()

    %Game{game | players: players}
  end

  def reset_player!(%Game{} = game, secret: secret) do
    {:ok, player} = fetch_player(game, secret)

    upsert_player(game, secret, %Player{
      player
      | boom: player.boom + 1
    })
  end

  def reset_players(%Game{} = game) do
    secrets = Map.keys(game.players)
    Enum.reduce(secrets, game, fn secret, game -> Game.reset_player!(game, secret: secret) end)
  end

  def get_player_positions(%Game{} = game) do
    Map.values(game.players)
    |> Enum.map(fn %Player{lat: lat, long: long} -> {lat, long} end)
    |> MapSet.new()
  end

  def upsert_player(%Game{} = game, secret, player) do
    %Game{game | players: [player | game.players]}
  end

  def upsert_clock(%Game{} = game) do
    %Game{game | updated_at: now()}
  end
end

defmodule World do
  @moduledoc false
  @history_limit 45

  defp move(%Game{} = game, %Player{} = player) do
  end
end
