defmodule CruftyCrafts.Cron do
  @moduledoc """
  checks for expired games periodically
  """
  use GenServer

  alias CruftyCrafts.GameManager

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    :timer.apply_interval(Game.expire_seconds() * 1000, GameManager, :kill_expired_games, [])
    :timer.apply_interval(Game.game_loop_ms(), GameManager, :game_tick, [])
    {:ok, state}
  end
end
