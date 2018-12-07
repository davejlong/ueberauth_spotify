defmodule Ueberauth.Strategy.Spotify.OAuth do
  @moduledoc """
  OAuth2 for Spotify.

  Add `client_id` and `client_secret` to your configuration:

      config :ueberauth, Ueberauth.Strategy.Spotify.OAuth,
        client_id: System.get_env("SPOTIFY_CLIENT_ID"),
        client_secret: System.get_env("SPOTIFY_CLIENT_SECRET")
  """

  use OAuth2.Strategy

  @account_url "https://accounts.spotify.com"

  @defaults [
    strategy: __MODULE__,
    site: "https://api.spotify.com/",
    authorize_url: "#{@account_url}/authorize",
    token_url: "#{@account_url}/api/token"
  ]

  @doc """
  Construct a client for request to Spotify.

  This will be setup automatically for youi n `Ueberauth.Strategy.Spotify`.

  These options are only usefule for usage outside the normal callback phase of Ueberauth.

  Examples:

      iex> Ueberauth.Strategy.Spotify.OAuth.client().__struct__
      OAuth2.Client
  """
  def client(opts \\ []) do
    @defaults
    |> Keyword.merge(config())
    |> Keyword.merge(opts)
    |> OAuth2.Client.new
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.

  Examples:

      iex> Ueberauth.Strategy.Spotify.OAuth.authorize_url!() =~ ~r/^https:\\/\\/accounts.spotify.com\\/authorize/
      true
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  @doc """
  Gets the Access Token from Spotify
  """
  def get_token!(params \\ [], opts \\ []) do
    IO.inspect(params, label: "Token Params")
    client = opts
    |> client
    |> OAuth2.Client.get_token!(params)

    client.token
  end

  @doc """
  Helper method to query Spotify API endpoints
  """
  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> OAuth2.Client.get(url, headers, opts)
  end

  @doc false
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  def get_token_with_refresh(refresh_token, redirect_uri) do
    client = client()
    opts = [
      redirect_uri: redirect_uri,
      strategy: OAuth2.Strategy.Refresh
    ]

    client = opts
    |> client
    |> put_param("grant_type", "refresh_token")
    |> put_param("refresh_token", refresh_token)
    |> put_header("Accept", "application/json")
    |> put_header("Authorization", "Basic #{Base.encode64(client.client_id <> ":" <> client.client_secret)}")
    |> OAuth2.Client.get_token!([])
  end

  defp config, do: Application.get_env(:ueberauth, Ueberauth.Strategy.Spotify.OAuth, [])
end
