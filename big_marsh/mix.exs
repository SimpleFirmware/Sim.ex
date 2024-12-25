defmodule BigMarsh.MixProject do
  use Mix.Project

  def project do
    [
      app: :big_marsh,
      version: "0.1.0",
      elixir: "~> 1.14.2",
      start_permanent: Mix.env() == :prod,
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
      {:distance, "~> 1.0"},
      {:decimal, "~> 2.2.0" }
    ]
  end
end
