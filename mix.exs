defmodule Moneris.Mixfile do
  use Mix.Project

  def project do
    [
      app: :moneris,
      version: "0.2.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      test_coverage: [tool: ExCoveralls],
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.0.0"},    # HTTP client
      {:sweet_xml, "~> 0.6.5"},     # XML parsing
      {:xml_builder, "~> 0.1.2"},   # make XML
      {:secure_random, "~> 0.5"},   # generate random strings for testing
      {:uuid, "~> 1.1"},            # generate UUIDs for transaction ids
      {:credo, "~> 0.8.10", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8.0", only: :test},  # Measure test coverage
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end

  defp package do
    [
      name: "moneris",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: [],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/SoundPays/moneris-elixir",
      }
    ]
  end

  defp description do
    """
    Unofficial Elixir client for processing payments through Moneris eSELECT+.
    """
  end
end
