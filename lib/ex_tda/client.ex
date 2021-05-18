defmodule ExTda.Client do
  @base_url "https://api.tdameritrade.com"

  def auth_url() do
    response_type = URI.encode_www_form("code")
    redirect_uri = URI.encode_www_form("https://127.0.0.1:4000")
    client_id = URI.encode_www_form("#{Application.get_env(:ex_tda, :client_id)}@AMER.OAUTHAP")
    base = "https://auth.tdameritrade.com/auth/token"

    "#{base}?response_type=#{response_type}&redirect_uri=#{redirect_uri}&client_id=#{client_id}"
  end

  def initial_token() do
    case :ets.lookup(ExTda.Cache.cache(), "initial_token") do
      [{"initial_token", it}] ->
        it

      _ ->
        url = "#{@base_url}/v1/oauth2/token"

        body = [
          grant_type: "authorization_code",
          client_id: "#{Application.get_env(:ex_tda, :client_id)}@AMER.OAUTHAP",
          access_type: "offline",
          code: ExTda.Cache.get_code(),
          redirect_uri: "https://127.0.0.1:4000"
        ]

        headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

        {:ok, %HTTPoison.Response{body: body}} =
          HTTPoison.post(url, URI.encode_query(body), headers)

        %{"access_token" => at} = Jason.decode!(body)
        :ets.insert(ExTda.Cache.cache(), {"initial_token", at})
        at
    end
  end
end
