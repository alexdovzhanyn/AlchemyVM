defmodule WaspVM.MixProject do
  use Mix.Project

  def project do
    [
      app: :wasp_vm,
      version: "0.7.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/ElixiumNetwork/WaspVM"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def description do
    "A WebAssembly Virtual Machine"
  end

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

  defp deps do
    [
      {:binary, "~> 0.0.5"},
      {:decimal, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
    ]
  end
end
