defmodule Missile do
  @moduledoc false

  @derive {Jason.Encoder, only: [:lat, :long, :bearing, :ticks]}
  defstruct id: nil,
            lat: nil,
            long: nil,
            bearing: 0,
            ticks: 0

  def next(%Missile{lat: lat, long: long, bearing: bearing, ticks: ticks} = missile) do
    {lat, long, bearing} = Game.next_lat_long(lat, long, bearing, 5)
    %Missile{missile | lat: lat, long: long, bearing: bearing, ticks: ticks + 1}
  end
end

defmodule Player do
  @moduledoc false
  @collision_distance 0.003

  @derive {Jason.Encoder, only: [:handle, :lat, :long, :bearing]}
  defstruct handle: nil,
            index: 0,
            boom: 0,
            missiles: [],
            lat: nil,
            long: nil,
            bearing: 0

  def debug_players(players) do
    players
    |> Enum.map(fn %Player{lat: lat, long: long, bearing: bearing} ->
      %{
        lat: Projections.rad_to_deg(lat),
        long: Projections.rad_to_deg(long),
        bearing: Projections.rad_to_deg(bearing)
      }
    end)
  end

  def rotate(%Player{bearing: bearing} = player, angle) do
    %Player{player | bearing: Projections.mod(bearing + angle, 2 * :math.pi())}
  end

  def shoot(%Player{lat: lat, long: long, bearing: bearing, missiles: missiles} = player) do
    %Player{
      player
      | missiles: [%Missile{id: SmallID.new(), lat: lat, long: long, bearing: bearing} | missiles]
    }
  end

  def next(%Player{lat: lat, long: long, bearing: bearing, missiles: missiles} = player) do
    {lat, long, bearing} = Game.next_lat_long(lat, long, bearing)
    missiles = Enum.map(missiles, fn missile -> Missile.next(missile) end)
    %Player{player | lat: lat, long: long, bearing: bearing, missiles: missiles}
  end

  defp collisions(
         %Player{} = player,
         %Missile{lat: lat, long: long, bearing: bearing, ticks: ticks} = missile
       ) do
    {lat, long, bearing} = Game.next_lat_long(lat, long, bearing, 5)
    dist = Game.distance(player, missile)

    if dist > @collision_distance do
      {:ok, %Missile{missile | lat: lat, long: long, bearing: bearing, ticks: ticks + 1}}
    else
      {:boom, nil}
    end
  end

  def next_all(players) do
    players =
      Enum.map(players, fn {secret, player} -> {secret, Player.next(player)} end)
      |> Map.new()

    players
    # enemies = Enum.filter(players, fn {sec, _} -> sec != secret end)
    # collisions(players)
  end
end

defmodule Game do
  @moduledoc false
  @expire_seconds 60 * 60
  @game_loop_ms 100

  defstruct id: nil,
            host_secret: "",
            players: %{},
            updated_at: 0

  def public(%Game{players: players}) do
    Map.values(players)
  end

  def expire_seconds(), do: @expire_seconds
  def game_loop_ms(), do: @game_loop_ms

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
      lat: :math.pi() / 8,
      long: :math.pi() / 6,
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

  defp next_bearing(lat1, long1, lat2, long2) do
    delta_long = long2 - long1
    y = :math.sin(delta_long) * :math.cos(lat2)

    x =
      :math.cos(lat1) * :math.sin(lat2) -
        :math.sin(lat1) * :math.cos(lat2) * :math.cos(delta_long)

    bearing = :math.atan2(y, x)

    Projections.mod(bearing + :math.pi(), 2 * :math.pi())
  end

  def next_lat_long(lat1, long1, bearing, f \\ 1) do
    r = 1
    d = f * r / 50

    lat2 =
      :math.asin(
        :math.sin(lat1) * :math.cos(d / r) +
          :math.cos(lat1) * :math.sin(d / r) * :math.cos(bearing)
      )

    long2 =
      long1 +
        :math.atan2(
          :math.sin(bearing) * :math.sin(d / r) * :math.cos(lat1),
          :math.cos(d / r) - :math.sin(lat1) * :math.sin(lat2)
        )

    long2 = Projections.mod(long2 + 3 * :math.pi(), 2 * :math.pi()) - :math.pi()

    bearing = next_bearing(lat2, long2, lat1, long1)

    {lat2, long2, bearing}
  end

  def distance(%{lat: lat1, long: long1}, %{lat: lat2, long: long2}) do
    r = 1
    x = (long2 - long1) * :math.cos(0.5 * (lat1 + lat2))
    y = lat2 - lat1
    :math.sqrt(x * x + y * y) * r
  end

  def upsert_player(%Game{} = game, secret, player) do
    %Game{game | players: Map.put(game.players, secret, player)}
  end

  def upsert_clock(%Game{} = game) do
    %Game{game | updated_at: now()}
  end
end
