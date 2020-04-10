defmodule PaymongoElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :paymongo_elixir,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Paymongo Elixir",
      source_url: "https://github.com/pau-riosa/paymongo-elixir.git",
      docs: [
        main: "Paymongo Elixir",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PaymongoElixir.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:httpoison, "~> 1.6.2"}
    ]
  end
end
