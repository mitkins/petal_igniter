defmodule PetalIgniter.MixProject do
  use Mix.Project

  def project do
    [
      app: :petal_igniter,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:heroicons,
       [
         github: "tailwindlabs/heroicons",
         tag: "v2.1.5",
         sparse: "optimized",
         app: false,
         compile: false,
         depth: 1
       ]},
      {:lazy_html, ">= 0.0.0", only: :test},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 1.1"},
      {:igniter, "~> 0.7", only: [:dev, :test], optional: true}
    ]
  end

  defp elixirc_paths(:test),
    do: elixirc_paths(:dev) ++ ["test/support"]

  defp elixirc_paths(_),
    do: ["lib"]
end
