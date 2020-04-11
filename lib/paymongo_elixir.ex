defmodule PaymongoElixir do
  @moduledoc """
  Documentation for `PaymongoElixir`.
  for further references visit  [paymongo api references](https://developers.paymongo.com/reference#getting-started-with-your-api)
  """

  @url "https://api.paymongo.com"
  @source "/v1/sources"
  @payment "/v1/payments"
  @payment_intent "/v1/payment_intents"
  @payment_method "/v1/payment_methods"

  defmacro __using__(opts) do
    otp_app = Keyword.get(opts, :otp_app)
    client_id = Application.get_env(otp_app, :client_id)
    client_secret = Application.get_env(otp_app, :client_secret)

    quote bind_quoted: [client_id: client_id, client_secret: client_secret] do
      Application.put_env(:paymongo_elixir, :client_id, client_id)
      Application.put_env(:paymongo_elixir, :client_secret, client_secret)
    end
  end

  @doc """
  Generates list of payments

  Pass an argument of `:list_payments` to generate the lists.

  ## Examples

      iex> PaymongoElixir.list(:list_payments)
      %{
        "data" => [
          %{
            "id" => id,
            "type" => "payment",
            "attributes" => %{
              ...
              "status" => "paid"
            }
          }
        ]
      }
      
  """
  def list(request) do
    with {:ok, %HTTPoison.Response{} = data} <- request(request),
         %{"data" => _data} = data <- Jason.decode!(data.body) do
      data
    else
      %{"errors" => errors} ->
        {:error, errors}

      {:error, :request_not_found} ->
        {:error, :request_not_found}

      _ ->
        {:error, :no_payments}
    end
  end

  @doc """
  get request

  Pass argument request and id

  request can be: 

    * `:retrieve_payment` retrieves a payment + `id` with format `pay_123`
    * `:retrieve_payment_intent` retrieves a payment intent + `id` with format `pi_123`
    * `:retrieve_payment_method` retrieves a payment method + `id` with format `pm_123`

  if none of the above request was called, an `{:error, :request_not_found}` will be returned.

  ## Example: retrieve a payment

      iex> id = "pay_123"
      iex> PaymongoElixir.get(:retrieve_payment, id)
      %{
        "data" => %{
          "id" => pay_id,
          "type" => "payment",
          "attributes" => %{
            "status" => "paid"
            ...
          }
        }
      } 

  ## Example: retrieve a payment intent

      iex> id = "pi_123"
      iex> PaymongoElixir.get(:retrieve_payment_intent, id)
      %{
        "data" => %{
          "id" => "pi_123", 
          "type" => "payment_intent",
          "attributes" => %{
            "amount" => 10000,
            "status" => "awaiting_payment_method",
          }
        }
      } 

  ## Example: retrieve payment method

      iex> id = "pm_123"
      iex> PaymongoElixir.get(:retrieve_payment_method, id)
      %{
        "data" => %{
          "id" => "pm_123",
          "type" => "payment_method",
          "attributes" => %{
            "livemode" => false,
            "type" => "card",
            "billing" => nil,
            "details" => %{
              "last4" => "4345",
              "exp_month" => 12,
              "exp_year" => 2030,
              "cvc" => "123"
            }
          }
        }
      }

  """
  def get(request, id) do
    with {:ok, %HTTPoison.Response{} = data} <- request(request, id),
         %{"data" => _data} = data <- Jason.decode!(data.body) do
      data
    else
      %{"errors" => errors} ->
        {:error, errors}

      {:error, :request_not_found} ->
        {:error, :request_not_found}

      _ ->
        {:error, :invalid_transaction}
    end
  end

  @doc """
  Post requests 

  Pass arguments `request` + `params`. You can check out paymongo docs for the parameters.

  request can be: 

    * `:create_source` = creates a source. source can be `gcash` or `grab_pay`.
    * `:create_payment_source` = creates a payment for a source. source needs to be `chargeable` in order for you to get the payment. 
    * `:cancel_payment_intent` = cancels a payment intent.
    * `:attach_payment_intent` = attaches a payment method to a payment intent.
    * `:create_payment_intent` = creates a payment intent.
    * `:create_payment_method` = creates a payment method.

  if none of the above request was called, an `{:error, :request_not_found}` will be returned.

  ## Example: create a source

      iex> params = %{
      ...>         "data" => %{
      ...>           "attributes" => %{
      ...>             "type" => "gcash",
      ...>             "amount" => 10_000,
      ...>             "currency" => "PHP",
      ...>             "redirect" => %{
      ...>               "success" => "https://account.syd.localhost:4001/gcash",
      ...>               "failed" => "https://account.syd.localhost:4001/gcash"
      ...>             }
      ...>           }
      ...>         }
      ...>       }
      iex> PaymongoElixir.post(:create_source, params)
      %{
        "data" => %{
          "id" => "src_123",
          "type" => "source",
          "attributes" => %{
            "amount" => 10_000,
            "billing" => nil,
            "currency" => "PHP",
            "livemode" => false,
            "redirect" => %{
              "success" => "https://example.com/gcash",
              "failed" => "https://example.com/gcash"
            },
            "status" => "pending",
            "type" => "gcash"
          }
        }
      }

  ## Example: create a payment source

      iex> source_id = "src_2RyFqt9C1TD5iuRAytzT41eg"
      iex> params = %{
      ...>  "data" => %{
      ...>    "attributes" => %{
      ...>      "amount" => 10_000,
      ...>      "currency" => "PHP",
      ...>      "source" => %{
      ...>        "id" => source_id,
      ...>        "type" => "source"
      ...>      }
      ...>    }
      ...>  }
      ...> }
      iex> PaymongoElixir.post(:create_payment_source, params)
      %{
        "data" => %{
          "attributes" => %{
            "access_url" => nil,
            "amount" => 10_000,
            "billing" => nil,
            "currency" => "PHP",
            "description" => nil,
            "external_reference_number" => nil,
            "fee" => 290,
            "livemode" => false,
            "status" => "paid",
          },
          "id" => "pay_123",
          "type" => "payment"
        }
      }

  ## Example: cancel payment intent

      iex> payment_intent_id = "pi_123"
      iex> PaymongoElixir.post(:cancel_payment_intent, payment_intent_id)
      %{
        "data" => %{
          "attributes" => %{
            "amount" => 10_000,
            "currency" => "PHP",
            "description" => nil,
            "last_payment_error" => nil,
            "livemode" => false,
            "metadata" => nil,
            "next_action" => nil,
            "payment_method_allowed" => ["card"],
            "payments" => [],
            "statement_descriptor" => nil,
            "status" => "cancelled",
          },
          "id" => "pi_123",
          "type" => "payment_intent"
        }
      }

  ## Example: attach a payment method to a payment intent

      iex> client_key = "client_key_123"
      iex> payment_intent_id = "pi_123"
      iex> payment_method_id = "pm_123"
      iex> query_params = %{"id" => payment_intent_id, "client_key" => client_key}
      iex> body_params =  %{
      ...>  "data" => %{
      ...>    "attributes" => %{
      ...>      "payment_method" => payment_method_id
      ...>    }
      ...>  }
      ...>}
      iex>  params = %{
      ...>  "query_params" => query_params,
      ...>  "body_params" => body_params
      ...>}
      iex> PaymongoElixir.post(:attach_payment_intent, params)
      %{
        "data" => %{
          "attributes" => %{
            "amount" => 10_000,
            "status" => "succeeded",
            "livemode" => false,
            "payment_method_allowed" => ["card"],
            "payments" => [
              %{
                "attributes" => %{
                  "amount" => 10_000,
                  "billing" => nil,
                  "currency" => "PHP",
                  "description" => nil,
                  "livemode" => false,
                  "status" => "paid",
                },
                "id" => "pay_123",
                "type" => "payment"
              }
            ],
            "next_action" => nil,
            "metadata" => nil
            }
          }
        }

  ## Example: create payment intent

      iex> params = %{
      ...>  "data" => %{
      ...>    "attributes" => %{
      ...>      "amount" => 10_000,
      ...>      "payment_method_allowed" => ["card"],
      ...>      "currency" => "PHP"
      ...>    }
      ...>  }
      ...>}
      iex> PaymongoElixir.post(:create_payment_intent, params)
      %{
        "data" => %{
          "attributes" => %{
            "amount" => 10_000,
            "currency" => "PHP",
            "description" => nil,
            "statement_descriptor" => nil,
            "status" => "awaiting_payment_method",
            "livemode" => false,
            "payment_method_allowed" => ["card"],
            "payments" => [],
            "next_action" => nil,
            "metadata" => nil
          }
        }
      }

  ## Example: create payment method

      iex> params = %{
      ...>  "data" => %{
      ...>    "attributes" => %{
      ...>      "type" => "card",
      ...>      "details" => %{
      ...>        "card_number" => "4343434343434345",
      ...>        "exp_month" => 12,
      ...>        "exp_year" => 2030,
      ...>        "cvc" => "123"
      ...>      }
      ...>    }
      ...>  }
      ...>}
      iex> PaymongoElixir.post(:create_payment_method, params)
      %{
        "data" => %{
          "id" => "pm_123",
          "type" => "payment_method",
          "attributes" => %{
            "livemode" => false,
            "type" => "card",
            "billing" => nil,
            "details" => %{
              "last4" => "4345",
              "exp_month" => 12,
              "exp_year" => 2030,
              "cvc" => "123"
            }
          }
        }
      }

  """
  def post(request, params) do
    with {:ok, %HTTPoison.Response{} = data} <- request(request, params),
         %{"data" => _data} = data <- Jason.decode!(data.body) do
      data
    else
      %{"errors" => errors} ->
        {:error, errors}

      {:error, :request_not_found} ->
        {:error, :request_not_found}

      _ ->
        {:error, :invalid_transaction}
    end
  end

  # Private Functions

  # request/2
  defp request(:create_source, params),
    do: do_request(:post, @source, params, secret_headers())

  defp request(:create_payment_source, params),
    do: do_request(:post, @payment, params, secret_headers())

  defp request(:retrieve_payment, "pay_" <> _generated_code = id),
    do: do_request(:get, "#{@payment}/#{id}", secret_headers())

  defp request(:cancel_payment_intent, "pi_" <> _generated_code = id),
    do: do_request(:post, "#{@payment_intent}/#{id}/cancel", [], secret_headers())

  defp request(
         :attach_payment_intent,
         %{"query_params" => query_params, "body_params" => body_params} = _params
       ) do
    with client_key <- URI.encode_query(client_key: query_params["client_key"]),
         query_params <- "#{query_params["id"]}/attach?#{client_key}" do
      do_request(:post, "#{@payment_intent}/#{query_params}", body_params, secret_headers())
    end
  end

  defp request(:retrieve_payment_intent, "pi_" <> _generated_code = id),
    do: do_request(:get, "#{@payment_intent}/#{id}", secret_headers())

  defp request(:create_payment_intent, params),
    do: do_request(:post, @payment_intent, params, secret_headers())

  defp request(:retrieve_payment_method, "pm_" <> _generated_code = id),
    do: do_request(:get, "#{@payment_method}/#{id}", public_headers())

  defp request(:create_payment_method, params),
    do: do_request(:post, @payment_method, params, public_headers())

  defp request(_request, _params), do: {:error, :request_not_found}

  defp request(:list_payments),
    do: do_request(:get, @payment, secret_headers())

  defp request(_request), do: {:error, :request_not_found}

  # do_request/4

  defp do_request(:post, url, params, headers) do
    params = Jason.encode!(params)
    HTTPoison.post(@url <> url, params, headers)
  end

  defp do_request(_service, _url, {:error, _value}, _headers), do: {:error, :request_not_found}

  # do_request/3
  defp do_request(:get, url, headers), do: HTTPoison.get(@url <> url, headers)

  defp public_headers do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Basic #{public_key_base64()}"}
    ]
  end

  defp secret_headers do
    [
      {"accept", "application/json"},
      {"content-type", "application/json"},
      {"authorization", "Basic #{secret_key_base64()}"}
    ]
  end

  defp public_key_base64 do
    Base.encode64(
      Application.get_env(:paymongo_elixir, :client_key) <>
        ":"
    )
  end

  defp secret_key_base64 do
    Base.encode64(
      Application.get_env(:paymongo_elixir, :client_secret) <>
        ":"
    )
  end
end
