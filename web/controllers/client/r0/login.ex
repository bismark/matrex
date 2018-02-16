defmodule Matrex.Controllers.Client.R0.Login do
  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.Identifier

  @login_type "m.login.password"

  def get(_conn, _params) do
    {:ok, %{flows: [%{type: @login_type}]}}
  end

  def post(conn, _params) do
    with {:ok, args} <- parse_args(conn.body_params),
         {:ok, {tokens, user_id}} <- DB.login(args.user, args.password) do
      {access_token, refresh_token} = tokens

      resp = %{
        user_id: user_id,
        access_token: access_token,
        refesh_token: refresh_token,
        home_server: user_id.hostname
      }

      {:ok, resp}
    end
  end

  defp parse_args(params) do
    args = %{}

    with {:ok, args} <- required(:user, params, args, type: :string, post: &parse_user/1),
         {:ok, args} <- required(:password, params, args, type: :string),
         {:ok, args} <- required(:type, params, args, type: :string, post: &validate_type/1) do
      {:ok, args}
    else
      {:error, {:unknown, :type}} -> {:error, :unknown}
      error -> error
    end
  end

  defp validate_type(@login_type), do: {:ok, @login_type}
  defp validate_type(_), do: {:error, :unknown}

  @spec parse_user(String.t()) :: {:ok, Identifier.user()}
  defp parse_user(user) do
    case Identifier.parse(user, :user) do
      :error -> {:ok, Identifier.new(:user, user)}
      res -> res
    end
  end
end
