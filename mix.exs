defmodule Roombex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :roombex,
     version: "0.1.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     description: """
       Implements the Roomba binary protocol. Send and receive binary data using elixir data structures and simple functions.
       """,
      docs: [
        main: "readme",
        extras: ["README.md"],
      ],
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:nerves_uart, "~> 0.1.2", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["Michael Ries"],
      licenses: ["MIT"],
      links: %{
        github: "https://github.com/mmmries/roombex",
        docs: "http://hexdocs.pm/roombex",
      }
    ]
  end
end
