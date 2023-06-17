defmodule CruftyCraftsWeb.PageController do
  use CruftyCraftsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
