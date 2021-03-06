defmodule ExTda.Client do
  @base_url "https://api.tdameritrade.com"

  def headers() do
    [{"access_token", at}] = :ets.lookup(:kv, "access_token")
    %{"Authorization" => "Bearer #{at}"}
  end

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

  def get_accounts() do
    url = "#{@base_url}/v1/accounts"
    %HTTPoison.Response{body: body} = HTTPoison.get!(url, headers())

    Jason.decode!(body)
  end

  def get_option_chain(symbol, contractType \\ "ALL", range \\ "ALL") do
    url = "#{@base_url}/v1/marketdata/chains"

    params = %{
      symbol: symbol,
      includeQuotes: true,
      contractType: contractType,
      range: range
    }

    new_url = "#{url}?#{URI.encode_query(params)}"
    %HTTPoison.Response{body: body} = HTTPoison.get!(new_url, headers())

    %{"callExpDateMap" => calls, "putExpDateMap" => puts, "underlying" => underlying} =
      Jason.decode!(body)

    %{calls: calls, puts: puts, underlying: underlying}
  end
end
