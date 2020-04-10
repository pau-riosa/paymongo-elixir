use Mix.Config

config :exvcr,
  filter_request_headers: ["authorization"],
  response_headers_blacklist: ["X-Request-Id", "ETag"]
