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
      Application.put_env(:paymongo, :client_id, client_id)
      Application.put_env(:paymongo, :client_secret, client_secret)
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
          "id" => payment_intent_id, 
          "type" => "payment_intent",
          "attributes" => %{
            "amount" => 10000,
            "currency" => "PHP",
            "description" => nil,
            "statement_descriptor" => nil,
            "status" => "awaiting_payment_method",
            "livemode" => false,
            "client_key" => _client_key,
            "created_at" => _created_at,
            "updated_at" => _updated_at,
            "last_payment_error" => nil,
            "payment_method_allowed" => ["card"],
            "payment_method_options" => %{
              "card" => %{"request_three_d_secure" => "automatic"}
            },
            "payments" => [],
            "next_action" => nil,
            "metadata" => nil
          }
        }
      } 

  ## Example: retrieve payment method

      iex> id = "pm_123"
      iex> PaymongoElixir.get(:retrieve_payment_method, id)
      %{
        "data" => %{
          "id" => payment_method_id,
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
  post requests  
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
      Application.get_env(:paymongo, :client_id) <>
        ":"
    )
  end

  defp secret_key_base64 do
    Base.encode64(
      Application.get_env(:paymongo, :client_secret) <>
        ":"
    )
  end
end
