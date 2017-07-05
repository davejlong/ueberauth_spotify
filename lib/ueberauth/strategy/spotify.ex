defmodule Ueberauth.Strategy.Spotify do
  @moduledoc """
  Spotify Strategy for Überauth
  """

  use Ueberauth.Strategy, uid_field: :uid, default_scope: "user-read-email"

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  # alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial reuqest for Spotify authentication.

  Step 1 from https://developer.spotify.com/web-api/authorization-guide/#authorization_code_flow
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    opts = [scope: scopes]
    |> with_optional(:show_dialog, conn)
    |> with_param(:state, conn)
    |> Keyword.put(:response_type, "code")
    |> Keyword.put(:redirect_uri, callback_url(conn))

    redirect!(conn, Ueberauth.Strategy.Spotify.OAuth.authorize_url!(opts))
  end

  @doc """
  Handles the callback from Spotify.

  Step 3 from https://developer.spotify.com/web-api/authorization-guide/#authorization_code_flow
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    opts = [redirect_uri: callback_url(conn)]
    token = Ueberauth.Strategy.Spotify.OAuth.get_token!([code: code], opts)

    if token.access_token == nil do
      conn |> set_errors!([error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    conn |> set_errors!([error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:spotify_user, nil)
    |> put_private(:spotify_token, nil)
  end

  @doc """
  Fetches the UID field from the response
  """
  def uid(conn), do: conn.private.spotify_user["id"]

  @doc """
  Fetches the Credentials from the response
  """
  def credentials(conn) do
    token = conn.private.spotify_token
    scopes = (token.other_params["scope"] || "") |> String.split(",")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token_type: Map.get(token, :token_type),
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @doc """
  Fetches the Info about the user from the response
  """
  def info(conn) do
    user = conn.private.spotify_user

    %Info{
      name: user["display_name"],
      email: user["email"],
      image: user["images"] |> List.first |> Map.get("url"),
      urls: user["external_urls"]
    }
  end

  defp fetch_user(conn, token) do
    conn = conn |> put_private(:spotify_token, token)
    path = "https://api.spotify.com/v1/me"

    case Ueberauth.Strategy.Spotify.OAuth.get(token, path) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        conn |> set_errors!([error("token", "unauthorized")])
      {:ok, %OAuth2.Response{status_code: status_code, body: user}} when status_code in 200..399 ->
        conn |> put_private(:spotify_user, user)
      {:error, %OAuth2.Error{reason: reason}} ->
        conn |> set_errors!([error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_param(opts, key, conn) do
    if value = conn.params[to_string(key)], do: Keyword.put(opts, key, value), else: opts
  end

  defp with_optional(opts, key, conn) do
    if option(conn, key), do: Keyword.put(opts, key, option(conn, key)), else: opts
  end
end
