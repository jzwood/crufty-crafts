defmodule CruftyCraftsWeb.LiveGame do
  @moduledoc """
  liveview representation of a specific game
  """

  use Phoenix.LiveView
  use Phoenix.HTML
  alias CruftyCraftsWeb.GameComponent

  @hammer_retroazimuthal "hammer-retroazimuthal"
  @azimuthal_equidistant "azimuthal-equidistant"
  @cassini "cassini"
  @equirectangular "equirectangular"

  def mount(%{"game_id" => "random"} = session, params, socket) do
    with [game_id | _games] <- CruftyCrafts.GameManager.list_games(),
         session <- Map.replace(session, "game_id", game_id),
         {:ok, socket} <- mount(session, params, socket) do
      {:ok, socket}
    else
      _ -> {:ok, assign(socket, :game, %Game{})}
    end
  end

  def mount(%{"game_id" => game_id, "projection" => projection} = _session, _params, socket) do
    case CruftyCrafts.GameManager.debug(game_id: game_id) do
      %Game{} = game ->
        CruftyCraftsWeb.Endpoint.subscribe(game_id)
        {:ok, assign(socket, game: game, projection: projection)}

      _ ->
        {:ok, assign(socket, :game, %Game{})}
    end
  end

  def mount(%{"game_id" => game_id} = _session, params, socket) do
    mount(%{"game_id" => game_id, "projection" => nil}, params, socket)
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, msg.payload)}
  end

  def update_game(game: %Game{id: game_id} = game) do
    CruftyCraftsWeb.Endpoint.broadcast_from(self(), game_id, "update_game", game: game)
  end

  def project(projection, lat, long) do
    case projection do
      nil -> Projections.hammer_retroazimuthal_projection(lat, long)
      @hammer_retroazimuthal -> Projections.hammer_retroazimuthal_projection(lat, long)
      @azimuthal_equidistant -> Projections.azimuthal_equidistant_projection(lat, long)
      @cassini -> Projections.cassini_projection(lat, long)
      @equirectangular -> Projections.equirectangular_projection(lat, long)
    end
  end

  def meridians(projection) do
    case projection do
      nil -> Projections.hammer_retroazimuthal_meridians()
      @hammer_retroazimuthal -> Projections.hammer_retroazimuthal_meridians()
      @azimuthal_equidistant -> Projections.azimuthal_equidistant_meridians()
      @cassini -> Projections.cassini_meridians()
      @equirectangular -> Projections.equirectangular_meridians()
    end
  end

  def normalize_positions(maps, bounds, projection) do
    maps
    |> Enum.map(fn %{lat: lat, long: long} -> project(projection, lat, long) end)
    |> Enum.map(&Projections.normalize(&1, bounds))
    |> Enum.zip(maps)
  end

  def render(assigns) do
    ~H"""
    <div class="bg-black">
      <div class="absolute left-1 top-1">
        <%= for %Player{ handle: handle, boom: boom, index: index } <- Map.values(@game.players) do %>
          <p class={"handles craft-#{index} ttc ma2"}><%= handle %>: <%= -1 * boom %></p>
        <% end %>
      </div>
      <svg
        viewBox="0 0 1 1"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
        <%
          xys = meridians(@projection)
          bounds = Projections.bounds(xys)
          players = normalize_positions(Map.values(@game.players), bounds, @projection)
        %>
        <%= for {x, y} <- Enum.map(xys, &Projections.normalize(&1, bounds)) do %>
          <circle cx={x} cy={y} r="0.001" fill="#222" />
        <% end %>
        <%= for {{x, y}, %Player{index: index, handle: handle, missiles: missiles}} <- players do %>
          <circle id={handle} data-cx={x} data-cy={y} r="0.004" class={"craft craft-#{index}"} phx-hook="Animate" />
          <%
            missiles = normalize_positions(missiles, bounds, @projection)
          %>
          <%= for {{x, y}, %Missile{id: id}} <- missiles do %>
            <circle id={id} data-cx={x} data-cy={y} r="0.002" class={"missile missile-#{index}"} phx-hook="Animate" />
          <% end %>
        <% end %>
      </svg>
    </div>
    """
  end
end
