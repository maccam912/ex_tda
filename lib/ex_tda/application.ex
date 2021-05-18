defmodule ExTda.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ExTda.Endpoint, []},
      {ExTda.Cache, []}
      # Starts a worker by calling: ExTda.Worker.start_link(arg)
      # {ExTda.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExTda.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
