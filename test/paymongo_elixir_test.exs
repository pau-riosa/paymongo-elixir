defmodule PaymongoElixirTest do
  use ExUnit.Case, async: true
  doctest PaymongoElixir
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup do
    ExVCR.Config.cassette_library_dir("test/cassettes")
    :ok
    {:ok, %{impl: PaymongoElixirTest.Impl}}
  end

  defmodule Impl do
    @moduledoc false
    use PaymongoElixir, otp_app: :paymongo_elixir
  end

  describe "list payments" do
    test "generate list of payments" do
      use_cassette "generate list of payments" do
        assert %{"data" => [_ | _]} = PaymongoElixir.list(:list_payments)
      end
    end
  end
end
