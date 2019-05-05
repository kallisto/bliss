defmodule Bliss.Mixfile do
  use Mix.Project

  def project do
    [ app: :bliss,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      escript: [main_module: Bliss]] # , embed_elixir: true
  end

  def application do
    [extra_applications: [:logger]]
  end
end
