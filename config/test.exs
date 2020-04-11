use Mix.Config

config :paymongo_elixir,
  client_key: System.get_env("PAYMONGO_PUBLIC_KEY"),
  client_secret: System.get_env("PAYMONGO_SECRET_KEY")

config :exvcr,
  filter_request_headers: ["authorization"],
  response_headers_blacklist: ["X-Request-Id", "ETag"]
