# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :proj4,
  ecto_repos: [Proj4.Repo]

# Configures the endpoint
config :proj4, Proj4Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "w52AEu8yy4cqbxWZ18nvoYOtGEwgoPupMgkg5pmEg2v2tY8B/7ErmwqeO2myHDyk",
  render_errors: [view: Proj4Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Proj4.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
