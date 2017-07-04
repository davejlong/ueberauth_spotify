defmodule UeberauthSpotify.Mixfile do
  use Mix.Project

  @url "https://github.com/davejlong/ueberauth_spotify"
  @version "0.5.0"

  def project do
    [app: :ueberauth_spotify,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "Ueberauth Spotify Strategy",
     source_url: @url,
     homepage_url: @url,
     description: description(),
     deps: deps(),
     docs: docs(),
     package: package()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :oauth2, :ueberauth]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ueberauth, "~> 0.4"},
     {:oauth2, "~> 0.9"},

     {:credo, "~> 0.8", only: :dev, runtime: false},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false}]
  end

  defp docs do
     [extras: ["README.md", "LICENSE", "CONTRIBUTING.md"]]
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Dave Long"],
     licenses: ["MIT"],
     links: %{"GitHub": @url}]
  end

  defp description do
    """
    An Ueberauth strategy for Spotify authentication
    """
  end
end
