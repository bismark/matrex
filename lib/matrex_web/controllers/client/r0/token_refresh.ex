defmodule MatrexWeb.Controllers.Client.R0.TokenRefresh do
  use MatrexWeb, :controller

  import Matrex.Validation

  alias Matrex.DB

  def post(conn, _params) do
    with {:ok, args} <- parse_args(conn.body_params),
         {:ok, tokens} <- DB.refresh_auth(args.refresh_token) do
      {access_token, refresh_token} = tokens

      resp = %{
        access_token: access_token,
        refresh_token: refresh_token
      }

      {:ok, resp}
    end
  end

  defp parse_args(params) do
    args = %{}

    with {:ok, args} <- required(:refresh_token, params, args, type: :string) do
      {:ok, args}
    end
  end
end
