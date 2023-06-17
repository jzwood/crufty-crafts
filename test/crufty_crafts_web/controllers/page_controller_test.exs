defmodule CruftyCraftsWeb.PageControllerTest do
  use CruftyCraftsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "crufty crafts"
  end
end
