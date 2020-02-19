defmodule Proj4Web.Router do
  use Proj4Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Proj4Web do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/registration", PageController, :registration
  end

  # Other scopes may use custom stacks.
  # scope "/api", Proj4Web do
  #   pipe_through :api
  # end
end
