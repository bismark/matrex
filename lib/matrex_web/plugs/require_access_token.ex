defmodule MatrexWeb.Plugs.RequireAccessToken do
  alias Plug.Conn

  import Matrex.Validation
  import MatrexWeb.Errors

  def init(options), do: options

  def call(conn, _options) do
    res = required(:access_token, conn.query_params, %{}, type: :string)

    with {:ok, %{access_token: access_token}} <- res do
      Conn.assign(conn, :access_token, access_token)
    else
      {:error, _} ->
        conn
        |> json_error(:missing_token)
        |> Conn.halt()
    end
  end
end
