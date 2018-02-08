# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

hostname = "localhost"

# Configures the endpoint
config :matrex, Matrex.Endpoint,
  url: [host: hostname],
  secret_key_base: "sYxF7J03ixE4Uuzg67OByfLda8Yg7itDVtAvSQcKnLsWzmJi68iXjaVvXFbK0p4t",
  render_errors: [view: Matrex.ErrorView, accepts: ~w(json)],
  pubsub: [name: Matrex.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :matrex, hostname: hostname

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
