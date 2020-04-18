defmodule PaymongoElixir.MixProject do
  use Mix.Project

  @project_url "https://github.com/pau-riosa/paymongo-elixir.git"

  def project do
    [
      app: :paymongo_elixir,
      version: "1.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Paymongo Elixir",
      source_url: @project_url,
      homepage_url: @project_url,
      description: "Unofficial API Integration for Paymongo",
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Jethro Riosa"],
      licenses: ["MIT"],
      links: %{"Github" => @project_url}
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
      {:exvcr, "~> 0.11", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:httpoison, "~> 1.6.2"}
    ]
  end
end
