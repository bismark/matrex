defmodule Matrex.Controllers.Client.R0.Logout do
  use Matrex.Web, :authed_controller

  alias Matrex.DB

  def post(_conn, _params, access_token) do
    with :ok <- DB.logout(access_token), do: {:ok, %{}}
  end
end
