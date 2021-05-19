defmodule ExTda.Endpoint do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get _ do
    conn = Plug.Conn.fetch_query_params(conn)
    code = Map.get(conn.query_params, "code", nil)

    if !is_nil(code) do
      :ets.insert(:kv, {"code", code})
      {at, rt} = ExTda.Client.get_initial_tokens()
      :ets.insert(:kv, {"refresh_token", rt})
      :ets.insert(:kv, {"access_token", at})
    end

    token = :ets.lookup(:kv, "code")

    case token do
      [] ->
        conn
        |> Plug.Conn.put_resp_header("location", ExTda.Client.auth_url())
        |> Plug.Conn.resp(302, "You are being redirected to login.")
        |> Plug.Conn.send_resp()

      [{"code", code}] ->
        conn
        |> Plug.Conn.send_resp(200, code)
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    Plug.Cowboy.https(__MODULE__, [],
      port: 4000,
      otp_app: :ex_tda,
      keyfile: "~/ex_tda/localhost.key",
      certfile: "~/ex_tda/localhost.crt"
    )
  end
end
