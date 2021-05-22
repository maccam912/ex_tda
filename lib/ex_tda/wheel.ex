defmodule ExTda.Wheel do
  def suggest_contract(symbol) do
    # {:ok, conn} = Exqlite.Sqlite3.open(":memory:")
    {:ok, conn} = Exqlite.Sqlite3.open("puts.db")

    :ok =
      Exqlite.Sqlite3.execute(
        conn,
        "create table puts (symbol text, dte integer, bid decimal, delta decimal, strike decimal, exp text, prem_per_day decimal GENERATED ALWAYS AS (bid/dte) VIRTUAL)"
      )

    %{puts: puts} = ExTda.Client.get_option_chain(symbol, "PUT", "OTM")

    puts
    |> Stream.map(fn {dt, contracts} ->
      [exp, dte] = String.split(dt, [":"])

      values_lines =
        contracts
        |> Stream.map(fn {strike, [%{"bid" => bid, "delta" => delta}]} ->
          if delta != "NaN" do
            # "(#{dte}, #{bid}, #{delta}, #{strike}, '#{exp}')"
            query =
              IO.inspect(
                "insert into puts (symbol, dte, bid, delta, strike, exp) values ('#{symbol}', #{dte}, #{bid}, #{delta}, #{strike}, '#{exp}')"
              )

            :ok = Exqlite.Sqlite3.execute(conn, query)
          end
        end)
        |> Enum.join(",")

      # query = IO.inspect "insert into puts (dte, bid, delta, strike, exp) values #{values_lines}"
      # :ok = Exqlite.Sqlite3.execute(conn, query)
    end)
    |> Stream.run()

    conn
  end
end
