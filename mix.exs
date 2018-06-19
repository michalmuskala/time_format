defmodule TimeFormat.MixProject do
  use Mix.Project

  def project do
    [
      app: :time_format,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    []
  end
end
