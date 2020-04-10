# PaymongoElixir

## Installation

```elixir
def deps do
  [
    {:paymongo_elixir, "~> 0.1.0"}
  ]
end
```
Documentation can be found at [https://hexdocs.pm/paymongo_elixir](https://hexdocs.pm/paymongo_elixir).

## Development

1. register as a developer in paymongo in [paymongo developer dashboard](https://dashboard.paymongo.com/signup)
2. In your `dev.exs` and `test.exs` copy your public_key as `client_key` and secret_key as `client_secret`

```elixir
config :paymongo_elixir
 client_key: <--client-key-->,
 client_secret: <--client-secret-->
```

**Notes**: Implementing in production requires you to activate your account that will give live `public_key` & `secret_key`. Copy the setup that is in your dev.exs or test.exs.

3. create a module to define the paymongo-elixir.

```elixir
defmodule MyApp.Paymongo do
  use PaymongoElixir, otp_app: :paymongo_elixir
end
```
4. now you may use it. 

```elixir
iex> PaymongoElixir.list(:list_payments)
```

## Contribution
Bug reports and pull requests are welcome on GitHub at https://github.com/pau-riosa/paymongo-elixir. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org/) code of conduct.


## Running Test
NOTES: please make sure that you already setup your elixir dev machine.

1. register as a developer in paymongo in [paymongo developer dashboard](https://dashboard.paymongo.com/signup)
2. export your `public_keys` on your system environment as `PAYMONGO_PUBLIC_KEY`
3. export your `secret_keys` on your system environment as `PAYMONGO_SECRET_KEY`
4. run the following

```elixir
mix do deps.get, compile
mix test
```
