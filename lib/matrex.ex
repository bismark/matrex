defmodule Matrex do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Matrex.DB, []),
      supervisor(Matrex.Endpoint, []),
    ]

    opts = [strategy: :one_for_one, name: Matrex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Matrex.Endpoint.config_change(changed, removed)
    :ok
  end
end
