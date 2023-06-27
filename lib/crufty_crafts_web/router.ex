defmodule CruftyCraftsWeb.Router do
  use CruftyCraftsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CruftyCraftsWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CruftyCraftsWeb do
    pipe_through :api

    get "/host/:handle", GameController, :host
    get "/game/:game_id/join/:handle", GameController, :join
    get "/game/:game_id/player/:secret/info", GameController, :info
    get "/game/:game_id/player/:secret/rotate/:angle", GameController, :rotate
    get "/game/:game_id/player/:secret/reset", GameController, :reset
    get "/game/:game_id/player/:secret/kick/:handle", GameController, :kick
    get "/game/:game_id/kill", GameController, :kill
  end

  scope "/", CruftyCraftsWeb do
    pipe_through :browser

    live("/", LiveHome)
    live("/worlds", LiveWorlds)
    live("/game/:game_id", LiveGame)
    live("/game/:game_id/:projection", LiveGame)
  end

  # Other scopes may use custom stacks.
  # scope "/api", CruftyCraftsWeb do
  #   pipe_through :api
  # end
end
