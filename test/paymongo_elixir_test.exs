defmodule PaymongoElixirTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @grab_pay_valid_test_params %{
    "data" => %{
      "attributes" => %{
        "type" => "grab_pay",
        "amount" => 10_000,
        "currency" => "PHP",
        "redirect" => %{
          "success" => "https://localhost:4001/gcash",
          "failed" => "https://localhost:4001/gcash"
        }
      }
    }
  }

  @gcash_valid_test_params %{
    "data" => %{
      "attributes" => %{
        "type" => "gcash",
        "amount" => 10_000,
        "currency" => "PHP",
        "redirect" => %{
          "success" => "https://localhost:4001/gcash",
          "failed" => "https://localhost:4001/gcash"
        }
      }
    }
  }

  @payment_method_valid_test_params %{
    "data" => %{
      "attributes" => %{
        "type" => "card",
        "details" => %{
          "card_number" => "4343434343434345",
          "exp_month" => 12,
          "exp_year" => 2030,
          "cvc" => "123"
        }
      }
    }
  }

  @payment_method_invalid_test_params %{
    "data" => %{
      "attributes" => %{
        "type" => "card",
        "details" => %{
          "card_number" => "4343434343434345",
          "exp_month" => "12",
          "exp_year" => 2030,
          "cvc" => "123"
        }
      }
    }
  }

  @payment_intent_valid_test_params %{
    "data" => %{
      "attributes" => %{
        "amount" => 10_000,
        "payment_method_allowed" => ["card"],
        "currency" => "PHP"
      }
    }
  }

  @payment_intent_invalid_test_params %{
    "data" => %{
      "attributes" => %{
        "amount" => "10_000",
        "payment_method_allowed" => ["card"],
        "currency" => "PHP"
      }
    }
  }
  setup do
    ExVCR.Config.cassette_library_dir("test/cassettes")
    :ok
    {:ok, %{impl: PaymongoElixirTest.Impl}}
  end

  defmodule Impl do
    @moduledoc false
    use PaymongoElixir, otp_app: :paymongo_elixir
  end

  describe "source" do
    test "create payment via source" do
      use_cassette "create payment for source" do
        # source needed to be chargeable 
        source_id = "src_qbjSqg75QdCNhYGgq1FyhJFv"

        params = %{
          "data" => %{
            "attributes" => %{
              "amount" => 10_000,
              "currency" => "PHP",
              "source" => %{
                "id" => source_id,
                "type" => "source"
              }
            }
          }
        }

        assert %{
                 "data" => %{
                   "attributes" => %{
                     "access_url" => nil,
                     "amount" => 10_000,
                     "billing" => nil,
                     "created_at" => _created_at,
                     "currency" => "PHP",
                     "description" => nil,
                     "external_reference_number" => nil,
                     "fee" => 290,
                     "livemode" => false,
                     "net_amount" => 9710,
                     "paid_at" => _paid_at,
                     "payout" => nil,
                     "source" => %{"id" => ^source_id, "type" => "gcash"},
                     "statement_descriptor" => nil,
                     "status" => "paid",
                     "updated_at" => _update_at
                   },
                   "id" => _pay_id,
                   "type" => "payment"
                 }
               } = PaymongoElixir.post(:create_payment_source, params)
      end
    end

    test "gcash with valid params" do
      use_cassette "create source gcash" do
        assert %{
                 "data" => %{
                   "id" => _id,
                   "type" => "source",
                   "attributes" => %{
                     "amount" => 10_000,
                     "billing" => nil,
                     "currency" => "PHP",
                     "livemode" => false,
                     "redirect" => %{
                       "success" => "https://localhost:4001/gcash",
                       "failed" => "https://localhost:4001/gcash"
                     },
                     "status" => "pending",
                     "type" => "gcash",
                     "created_at" => _created_at
                   }
                 }
               } = PaymongoElixir.post(:create_source, @gcash_valid_test_params)
      end
    end

    test "grab_pay with valid params" do
      use_cassette "create source grab_pay" do
        assert %{
                 "data" => %{
                   "id" => _id,
                   "type" => "source",
                   "attributes" => %{
                     "amount" => 10_000,
                     "billing" => nil,
                     "currency" => "PHP",
                     "livemode" => false,
                     "redirect" => %{
                       "success" => "https://localhost:4001/gcash",
                       "failed" => "https://localhost:4001/gcash"
                     },
                     "status" => "pending",
                     "type" => "grab_pay",
                     "created_at" => _created_at
                   }
                 }
               } = PaymongoElixir.post(:create_source, @grab_pay_valid_test_params)
      end
    end
  end

  describe "payment" do
    test "GET list payment" do
      use_cassette "list payments" do
        # this will pass since I already have list of payments in the account
        # will error if you don't have any succeed transaction yet. 
        assert %{"data" => [_ | _]} = PaymongoElixir.list(:list_payments)
        assert {:error, :request_not_found} = PaymongoElixir.list(:list)
      end
    end

    test "GET error retrive payment" do
      use_cassette "error retrieve payment" do
        assert {:error, errors} = PaymongoElixir.get(:retrieve_payment, "pay_lfjaslfufjasjfaksl")
        assert {:error, :request_not_found} = PaymongoElixir.get(:retrieve_payment, "123")
      end
    end

    test "GET retrive payment" do
      use_cassette "retrieve payment" do
        query_params = create_payment_intent()
        body_params = create_payment_method()
        {:ok, pay_id: pay_id} = attach_payment_method(body_params, query_params)

        assert %{
                 "data" => %{
                   "id" => ^pay_id,
                   "type" => "payment",
                   "attributes" => %{
                     "status" => "paid"
                   }
                 }
               } = PaymongoElixir.get(:retrieve_payment, pay_id)
      end
    end
  end

  describe "payment intent" do
    test "POST Cancel payment intent" do
      use_cassette "cancel payment intent" do
        # create payment intent
        %{"id" => payment_intent_id, "client_key" => client_key} = create_payment_intent()

        # cancel payment intent
        assert %{
                 "data" => %{
                   "attributes" => %{
                     "amount" => 10_000,
                     "client_key" => ^client_key,
                     "created_at" => _created_at,
                     "currency" => "PHP",
                     "description" => nil,
                     "last_payment_error" => nil,
                     "livemode" => false,
                     "metadata" => nil,
                     "next_action" => nil,
                     "payment_method_allowed" => ["card"],
                     "payment_method_options" => %{
                       "card" => %{"request_three_d_secure" => "automatic"}
                     },
                     "payments" => [],
                     "statement_descriptor" => nil,
                     "status" => "cancelled",
                     "updated_at" => _updated_at
                   },
                   "id" => ^payment_intent_id,
                   "type" => "payment_intent"
                 }
               } = PaymongoElixir.post(:cancel_payment_intent, payment_intent_id)
      end
    end

    test "POST attach payment method to payment intent" do
      use_cassette "attach payment method to intent" do
        # create payment intent 
        assert %{"id" => payment_intent_id, "client_key" => client_key} =
                 query_params = create_payment_intent()

        # create payment method 
        assert %{
                 "data" => %{
                   "attributes" => %{
                     "payment_method" => payment_method_id
                   }
                 }
               } = body_params = create_payment_method()

        params = %{
          "query_params" => query_params,
          "body_params" => body_params
        }

        # attach payment method to intent
        assert %{
                 "data" => %{
                   "attributes" => %{
                     "amount" => 10_000,
                     "currency" => "PHP",
                     "description" => nil,
                     "statement_descriptor" => nil,
                     "status" => "succeeded",
                     "livemode" => false,
                     "client_key" => ^client_key,
                     "created_at" => _created_at,
                     "updated_at" => _updated_at,
                     "last_payment_error" => nil,
                     "payment_method_allowed" => ["card"],
                     "payment_method_options" => %{
                       "card" => %{"request_three_d_secure" => "automatic"}
                     },
                     "payments" => [
                       %{
                         "attributes" => %{
                           "access_url" => nil,
                           "amount" => 10_000,
                           "billing" => nil,
                           "created_at" => _payment_created_at,
                           "currency" => "PHP",
                           "description" => nil,
                           "external_reference_number" => "",
                           "fee" => 1850,
                           "livemode" => false,
                           "net_amount" => 8150,
                           "paid_at" => _payment_paid_at,
                           "payout" => nil,
                           "source" => %{
                             "id" => "card_" <> _card,
                             "type" => "card"
                           },
                           "statement_descriptor" => nil,
                           "status" => "paid",
                           "updated_at" => _payment_updated_at
                         },
                         "id" => "pay_" <> _pay_id,
                         "type" => "payment"
                       }
                     ],
                     "next_action" => nil,
                     "metadata" => nil
                   }
                 }
               } = PaymongoElixir.post(:attach_payment_intent, params)
      end
    end

    test "GET with valid id" do
      use_cassette "get payment intent with valid id " do
        %{"data" => %{"id" => id}} =
          PaymongoElixir.post(:create_payment_intent, @payment_intent_valid_test_params)

        assert %{
                 "data" => %{
                   "attributes" => %{
                     "amount" => 10_000,
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
               } = PaymongoElixir.get(:retrieve_payment_intent, id)
      end
    end

    test "GET with invalid id" do
      use_cassette "pi with invalid id" do
        assert {:error, :request_not_found} = PaymongoElixir.get(:retrieve_payment_intent, "123")

        assert {:error, [_ | _] = _errors} =
                 PaymongoElixir.get(:retrieve_payment_intent, "pi_123")
      end
    end

    test "POST with valid params" do
      use_cassette "create valid payment intent" do
        assert %{
                 "data" => %{
                   "attributes" => %{
                     "amount" => 10_000,
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
               } = PaymongoElixir.post(:create_payment_intent, @payment_intent_valid_test_params)
      end
    end

    test "POST with invalid params" do
      use_cassette "create pi with invalid params" do
        assert {:error, error} =
                 PaymongoElixir.post(:create_payment_intent, @payment_intent_invalid_test_params)

        assert [
                 %{
                   "code" => "parameter_data_type_invalid",
                   "detail" => "amount should be an integer.",
                   "source" => %{"attribute" => "amount", "pointer" => "amount"}
                 }
               ] = error
      end
    end
  end

  describe "payment method" do
    test "GET with valid id" do
      use_cassette "get pm with valid id" do
        %{"data" => %{"id" => id}} =
          PaymongoElixir.post(:create_payment_method, @payment_method_valid_test_params)

        assert %{
                 "data" => %{
                   "id" => ^id,
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
               } = PaymongoElixir.get(:retrieve_payment_method, id)
      end
    end

    test "GET with invalid id" do
      use_cassette "get pm with invalid id" do
        assert {:error, :request_not_found} = PaymongoElixir.get(:retrieve_payment_method, "123")

        assert {:error, [_ | _] = _errors} =
                 PaymongoElixir.get(:retrieve_payment_method, "pm_123")
      end
    end

    test "POST with valid params" do
      use_cassette "create valid payment method" do
        assert %{
                 "data" => %{
                   "id" => _id,
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
               } = PaymongoElixir.post(:create_payment_method, @payment_method_valid_test_params)
      end
    end

    test "POST with invalid params" do
      use_cassette "create invalid payment method" do
        assert {:error, errors} =
                 PaymongoElixir.post(:create_payment_method, @payment_method_invalid_test_params)

        assert [
                 %{
                   "code" => "parameter_data_type_invalid",
                   "detail" => "details.exp_month should be an integer.",
                   "source" => %{"attribute" => "exp_month", "pointer" => "details.exp_month"}
                 }
               ] = errors
      end
    end
  end

  defp create_payment_method do
    %{"data" => %{"id" => payment_method_id}} =
      PaymongoElixir.post(:create_payment_method, @payment_method_valid_test_params)

    %{
      "data" => %{
        "attributes" => %{
          "payment_method" => payment_method_id
        }
      }
    }
  end

  defp create_payment_intent do
    %{
      "data" => %{
        "id" => payment_intent_id,
        "attributes" => %{
          "client_key" => client_key
        }
      }
    } = PaymongoElixir.post(:create_payment_intent, @payment_intent_valid_test_params)

    %{"id" => payment_intent_id, "client_key" => client_key}
  end

  defp attach_payment_method(body_params, query_params) do
    params = %{"query_params" => query_params, "body_params" => body_params}

    %{
      "data" => %{
        "attributes" => %{
          "payments" => [
            %{
              "attributes" => %{
                "status" => "paid"
              },
              "id" => pay_id,
              "type" => "payment"
            }
          ]
        }
      }
    } = PaymongoElixir.post(:attach_payment_intent, params)

    {:ok, pay_id: pay_id}
  end
end
