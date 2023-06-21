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

  def render(assigns) do
    ~H"""
    <div class="bg-black">
      <%= for %Player{ handle: handle, index: index } <- Map.values(@game.players) do %>
        <p class={"handles craft-#{index} ttc absolute top-1 left-1"}><%= handle %></p>
      <% end %>
      <svg
        viewBox="0 0 1 1"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
        <%
          xys = Projections.hammer_retroazimuthal_meridians()
          bounds = Projections.bounds(xys)
          players = @game.players
          |> Map.values()
          |> Enum.map(fn %Player{lat: lat, long: long} -> Projections.hammer_retroazimuthal_projection(lat, long) end)
          |> Enum.map(&Projections.normalize(&1, bounds))
          |> Enum.zip(Map.values(@game.players))
          |> IO.inspect
        %>
        <%= for {x, y} <- Enum.map(xys, &Projections.normalize(&1, bounds)) do %>
          <circle cx={x} cy={y} r="0.001" fill="#222" />
        <% end %>
        <%= for {{x, y}, %Player{index: index}} <- players do %>
          <circle cx={x} cy={y} r="0.002" class={"craft-#{index}"} />
        <% end %>
      </svg>
    </div>
    """
  end
end
