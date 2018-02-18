use Mix.Config

config :matrex, load_fixtures: true

config :matrex, MatrexWeb.Endpoint,
  http: [port: 4000],
  https: [
    port: 4443,
    otp_app: :matrex,
    keyfile: "priv/certs/devkey.pem",
    certfile: "priv/certs/devcert.pem"
  ],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
