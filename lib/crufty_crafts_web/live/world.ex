defmodule CruftyCraftsWeb.LiveGame do
  @moduledoc """
  liveview representation of a specific game
  """

  use Phoenix.LiveView
  use Phoenix.HTML
  alias CruftyCraftsWeb.GameComponent

  def mount(%{"game_id" => "random"} = session, params, socket) do
    with [game_id | _games] <- CruftyCrafts.GameManager.list_games(),
         session <- Map.replace(session, "game_id", game_id),
         {:ok, socket} <- mount(session, params, socket) do
      {:ok, socket}
    else
      _ -> {:ok, assign(socket, :game, %Game{})}
    end
  end

  def mount(%{"game_id" => game_id} = _session, _params, socket) do
    case CruftyCrafts.GameManager.debug(game_id: game_id) do
      %Game{} = game ->
        CruftyCraftsWeb.Endpoint.subscribe(game_id)
        {:ok, assign(socket, :game, game)}

      _ ->
        {:ok, assign(socket, :game, %Game{})}
    end
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, msg.payload)}
  end

  def update_game(game: %Game{id: game_id} = game) do
    CruftyCraftsWeb.Endpoint.broadcast_from(self(), game_id, "update_game", game: game)
  end

  # defp avg({x1, y1}, {x2, y2}), do: {0.5 * (x1 + x2), 0.5 * (y1 + y2)}
  defp manhattan_distance({x1, y1}, {x2, y2}), do: abs(x2 - x1) + abs(y2 - y1)

  def render(assigns) do
    ~H"""
    <div class="map-container">
      <svg
        viewBox="0 0 10 10"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
      <rect x="0" y="0" width="10" height="10" fill="black" shape-rendering="optimizeSpeed" />
        <%= for {x, y} <- Projections.meridians() do %>
          <circle cx={x} cy={y} r="0.01" stroke="white" />
        <% end %>
      </svg>
    </div>
    """
  end
end
