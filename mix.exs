defmodule WaspVM.MixProject do
  use Mix.Project

  def project do
    [
      app: :wasp_vm,
      version: "0.8.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/ElixiumNetwork/WaspVM",
      docs: docs()
    ]
  end

  defp deps do
    [
      {:binary, "~> 0.0.5"},
      {:decimal, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:benchee, "~> 0.13", only: :dev},
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description, do: "A WebAssembly Virtual Machine"

  defp package() do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Alex Dovzhanyn", "Matthew Eaton"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/ElixiumNetwork/WaspVM",
        "Elixium Network Website" => "https://www.elixiumnetwork.org"
      }
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/ElixiumNetwork/WaspVM",
      extras: ["README.md"]
    ]
  end
end
