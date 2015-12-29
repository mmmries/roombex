defmodule Roombex.Mixfile do
  use Mix.Project

  def project do
    [app: :roombex,
     version: "0.0.3",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     package: package,
     description: """
      Implements the Roomba binary protocol. Send and receive binary data using elixir data structures and simple functions.
    """]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:serial, "~> 0.1.2"}
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
