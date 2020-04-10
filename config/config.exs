use Mix.Config

config :paymongo_elixir,
  client_key: System.get_env("PAYMONGO_PUBLIC_KEY"),
  client_secret: System.get_env("PAYMONGO_SECRET_KEY")

import_config "#{Mix.env()}.exs"
