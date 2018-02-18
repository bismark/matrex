use Mix.Config

hostname = "localhost"

config :matrex, MatrexWeb.Endpoint,
  url: [host: hostname],
  secret_key_base: "sYxF7J03ixE4Uuzg67OByfLda8Yg7itDVtAvSQcKnLsWzmJi68iXjaVvXFbK0p4t",
  render_errors: [view: MatrexWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: MatrexWeb.PubSub, adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :matrex,
  hostname: hostname,
  load_fixtures: false

import_config "#{Mix.env()}.exs"
