defmodule ExTda.Wheel do
  def suggest_contract(symbol) do
    %{puts: puts} = ExTda.Client.get_option_chain(symbol, "PUT", "OTM")

    best =
      puts
      |> Stream.map(fn {dt, contracts} ->
        [exp, dte] = String.split(dt, [":"])

        {best_prem, strike} =
          IO.inspect(
            contracts
            |> Stream.filter(fn {_strike, [%{"delta" => delta}]} ->
              delta > -0.4 && delta < -0.2
            end)
            |> Stream.map(fn {strike, %{"bidPrice" => bid}} ->
              {bid / dte, strike}
            end)
            |> Enum.sort_by(fn {prem, _} -> prem end)
            |> List.first()
          )

        {best_prem, exp, strike}
      end)
      |> Enum.sort_by(fn {best_prem, _, _} -> best_prem end)
      |> List.first()

    best
  end
end
