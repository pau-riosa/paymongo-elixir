defmodule PaymongoElixir do
  @moduledoc """
  Documentation for `PaymongoElixir`.
  """
  @url "https://api.paymongo.com"
  @payment "/v1/payments"

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
  generate list of payments
  iex> list(:list_payments)
  iex> [
    %{"data" => 
      %{
        "id" => id,
        "type" => "payment",
        "attributes" => %{
          ...
          "status" => "paid"
        } 
      }
    }
  ]
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
