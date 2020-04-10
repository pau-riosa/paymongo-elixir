# PaymongoElixir

**TODO: Add description**

1. get methods
2. post methods
3. unit tests

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `paymongo_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:paymongo_elixir, "~> 0.1.0"}
  ]
end
```
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/paymongo_elixir](https://hexdocs.pm/paymongo_elixir).

## module implementation 
create a module to define the paymongo-elixir behavior
for example: paymongo.ex
```elixir
defmodule MyApp.Paymongo do
  use PaymongoElixir, otp_app: :paymongo_elixir
end
```

## config setup
in your `dev.exs` and `test.exs` setup your `client_keys [public_keys] and client_secret [client_secret]`
```elixir
config :paymongo_elixir
 client_key: <--client-key-->,
 client_secret: <--client-secret-->
```


