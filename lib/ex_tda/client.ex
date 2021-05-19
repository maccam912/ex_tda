defmodule ExTda.Client do
  @base_url "https://api.tdameritrade.com"

  def auth_url() do
    response_type = URI.encode_www_form("code")
    redirect_uri = URI.encode_www_form("https://127.0.0.1:4000")
    client_id = URI.encode_www_form("#{Application.get_env(:ex_tda, :client_id)}@AMER.OAUTHAP")
    base = "https://auth.tdameritrade.com/auth/token"

    "#{base}?response_type=#{response_type}&redirect_uri=#{redirect_uri}&client_id=#{client_id}"
  end

  def get_initial_tokens() do
    url = "#{@base_url}/v1/oauth2/token"

    [{"code", code}] = :ets.lookup(:kv, "code")

    payload = [
      grant_type: "authorization_code",
      client_id: "#{Application.get_env(:ex_tda, :client_id)}@AMER.OAUTHAP",
      access_type: "offline",
      code: code,
      redirect_uri: "https://127.0.0.1:4000"
    ]

    headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.post(url, URI.encode_query(payload), headers)

    %{"access_token" => at, "refresh_token" => rt} = Jason.decode!(body)
    {at, rt}
  end

  def get_access_token() do
    [{"refresh_token", refresh_token}] = :ets.lookup(:kv, "refresh_token")

    payload = [
      grant_type: "refresh_token",
      refresh_token: refresh_token,
      client_id: "#{Application.get_env(:ex_tda, :client_id)}@AMER.OAUTHAP"
    ]

    headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.post("#{@base_url}/v1/oauth2/token", URI.encode_query(payload), headers)

    %{"access_token" => at} = Jason.decode!(body)
    at
  end
end
