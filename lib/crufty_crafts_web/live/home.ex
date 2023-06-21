defmodule CruftyCraftsWeb.LiveHome do
  @moduledoc """
  liveview app homepage
  """
  use Phoenix.LiveView

  @game_list "games"

  def mount(_session, _params, socket) do
    CruftyCraftsWeb.Endpoint.subscribe(@game_list)
    game_ids = CruftyCrafts.GameManager.list_games()
    {:ok, assign(socket, :games, game_ids)}
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, games: msg.payload)}
  end

  def update_world_list(game_ids) do
    # this broadcast gets picked up by handle_info
    CruftyCraftsWeb.Endpoint.broadcast_from(
      self(),
      @game_list,
      "update_game_list",
      game_ids
    )
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-column min-vh-100">
      <main class="worlds mw8 center items-baseline gv3 gh4 ph3 pv2 pv4-m pv5-l">
        <h2>crufty crafts</h2>
        <p class="f4">
          pilot a spacecraft with AI.<br>
          shoot lasers.<br>
          PvP friends.
        </p>
        <h2>host</h2>
        <div>
          <pre class="break-spaces break-word">GET /api/host/&lt;handle&gt;</pre>
        </div>
        <h2>friends</h2>
        <pre class="break-spaces break-word">GET /api/game/&lt;game_id&gt;/join/&lt;handle&gt;</pre>
        <h2>api<sup class="courier normal">*</sup></h2>
        <pre class="break-spaces break-word">GET /api/game/&lt;game_id&gt;/player/&lt;secret&gt;/move/&lt;N|E|S|W&gt;</pre>
        <h2>learn</h2>
          <a class="f4" href="https://github.com/jzwood/crufty-crafts/#complete-api" target="_blank">api</a>
        <h2>watch</h2>
        <%= if length(@games) == 0 do %>
          <i class="f4">no games in progress</i>
        <% end %>
        <ol>
          <%= for game_id <- @games do %>
            <li>
              <a class="f4" data-phx-link="redirect" data-phx-link-state="push" href={"/game/#{ game_id }"}><%= game_id %></a>
            </li>
          <% end %>
        </ol>
      </main>
      <div class="flex-grow-1"></div>
      <footer class="flex items-center justify-between gh2 mt2 pv1 ph3">
        <div class="flex gh2 items-baseline">
          <h3 class="courier normal">*</h3>
          <i>api rate limit: 10 requests / second</i>
        </div>
        <a href="https://github.com/jzwood/crufty-crafts" target="_blank" class="flex flex-shrink-0">
          <img class="h2 mv1" src="/images/github-mark.svg" alt="view project on github"/>
        </a>
      </footer>
    </div>
    """
  end
end
