defmodule Matrex.Controllers.Client.R0.Logout do
  use Matrex.Web, :controller

  alias Matrex.DB

  def post(conn, _params) do
    access_token = conn.assigns[:access_token]

    with :ok <- DB.logout(access_token) do
      json(conn, %{})
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end
end
