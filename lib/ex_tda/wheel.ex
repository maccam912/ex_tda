defmodule ExTda.Wheel do
  require Logger

  def get_sp500_symbols() do
    url =
      "https://raw.githubusercontent.com/datasets/s-and-p-500-companies/master/data/constituents.csv"

    %HTTPoison.Response{body: body} = HTTPoison.get!(url)

    body
    |> String.split(["\n"])
    |> CSV.decode(headers: true)
    |> Stream.filter(fn {st, _} -> st == :ok end)
    |> Stream.map(fn {:ok, line} -> line end)
    |> Stream.map(fn %{"Symbol" => symbol} ->
      symbol
    end)
    |> Enum.to_list()
  end

  def suggest_contracts() do
    {:ok, conn} = Exqlite.Sqlite3.open("puts.db")

    :ok = create_table(conn)

    get_sp500_symbols()
    |> Flow.from_enumerable(stages: 2, min_demand: 0, max_demand: 2)
    |> Flow.map(fn symbol ->
      Logger.info("Getting #{symbol}")
      {symbol, get_options_insert_queries(symbol)}
    end)
    |> Flow.map(fn {symbol, queries} ->
      queries
      |> Enum.map(fn query ->
        Exqlite.Sqlite3.execute(conn, query)
      end)

      symbol
    end)
    |> Flow.run()
  end

  def create_table(conn) do
    :ok =
      Exqlite.Sqlite3.execute(
        conn,
        "create table if not exists puts
          (symbol text, dte integer, bid decimal, delta decimal, strike decimal, exp text,
          prem_per_day decimal GENERATED ALWAYS AS (bid/dte) VIRTUAL,
          prem_per_day_per_strike GENERATED ALWAYS AS ((bid/dte)/strike) VIRTUAL
          )"
      )

    :ok =
      Exqlite.Sqlite3.execute(
        conn,
        "create unique index if not exists symbol_strike_exp_i on puts (symbol, strike, exp)"
      )

    :ok
  end

  @spec get_options_insert_queries(binary) :: list
  def get_options_insert_queries(symbol) do
    %{puts: puts} = ExTda.Client.get_option_chain(symbol, "PUT", "OTM")

    puts
    |> Stream.map(fn {dt, contracts} ->
      [exp, dte] = String.split(dt, [":"])

      values_lines =
        contracts
        |> Stream.map(fn {strike, [%{"bid" => bid, "delta" => delta} | _]} ->
          if delta != "NaN" do
            "('#{symbol}', #{dte}, #{bid}, #{delta}, #{strike}, '#{exp}')"
          else
            nil
          end
        end)
        |> Stream.filter(fn item -> !is_nil(item) end)
        |> Enum.join(",")

      "insert into puts (symbol, dte, bid, delta, strike, exp) values #{values_lines}"
    end)
    |> Enum.to_list()
  end

  def suggest_contract_query(symbol) do
    # {:ok, conn} = Exqlite.Sqlite3.open(":memory:")
    {:ok, conn} = Exqlite.Sqlite3.open("puts.db")

    %{puts: puts} = ExTda.Client.get_option_chain(symbol, "PUT", "OTM")

    puts
    |> Stream.map(fn {dt, contracts} ->
      [exp, dte] = String.split(dt, [":"])

      values_lines =
        contracts
        |> Stream.map(fn {strike, [%{"bid" => bid, "delta" => delta} | _]} ->
          if delta != "NaN" do
            "('#{symbol}', #{dte}, #{bid}, #{delta}, #{strike}, '#{exp}')"
          else
            nil
          end
        end)
        |> Stream.filter(fn item -> !is_nil(item) end)
        |> Enum.join(",")

      query = "insert into puts (symbol, dte, bid, delta, strike, exp) values #{values_lines}"
      # May be :ok, or {:error, ...} if unique constraint exists
      Exqlite.Sqlite3.execute(conn, query)
    end)
    |> Stream.run()
  end
end
