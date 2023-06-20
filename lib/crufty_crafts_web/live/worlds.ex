defmodule CruftyCraftsWeb.LiveWorlds do
  @moduledoc """
  shows all world maps
  """

  use Phoenix.LiveView
  use Phoenix.HTML
  alias CruftyCraftsWeb.GameComponent

  def mount(_session, _params, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-black">
      <svg
        viewBox="0 0 1 1"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
        <%= for {x, y} <- Projections.hammer_retroazimuthal_meridians() do %>
          <circle cx={x} cy={y} r="0.001" fill="#444" />
        <% end %>
      </svg>
    </div>
    """
  end
end
