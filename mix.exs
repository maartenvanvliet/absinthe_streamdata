defmodule ArtemProp.MixProject do
  use Mix.Project

  @url "https://github.com/maartenvanvliet/absinthe_streamdata"
  def project do
    [
      app: :absinthe_streamdata,
      consolidate_protocols: false,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Create Graphql StreamData generator from an Absinthe schema",
      package: [
        maintainers: ["Maarten van Vliet"],
        licenses: ["MIT"],
        links: %{"GitHub" => @url},
        files: ~w(LICENSE README.md lib mix.exs .formatter.exs)
      ],
      docs: [
        canonical: "http://hexdocs.pm/absinthe_streamdata",
        source_url: @url
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:absinthe, "~> 1.6"},
      {:stream_data, "~> 0.5"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.23", only: [:dev, :test]}
    ]
  end
end
