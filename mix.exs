defmodule Matrex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :matrex,
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Matrex.Application, []}, extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.3"},
      {:cowboy, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:pbkdf2_elixir, "~> 0.12"},
      {:cors_plug, "~> 1.1"},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end
end
