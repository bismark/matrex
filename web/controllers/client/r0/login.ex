defmodule Matrex.Controllers.Client.R0.Login do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.UserID

  @login_type "m.login.password"

  def get(conn, _params) do
    json(conn, %{flows: [%{type: @login_type}]})
  end


  def post(conn, _params) do
    with {:ok, args} <- parse_args(conn.body_params),
         {:ok, {access_token, refresh_token}} <- DB.login(args.user, args.password)
    do
      hostname = Application.get_env(:matrex, :hostname)
      resp = %{
        user_id: UserID.fquid(args.user, hostname),
        access_token: access_token,
        refesh_token: refresh_token,
        home_server: hostname
      }
      json(conn, resp)
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end


  defp parse_args(params) do
    args = %{}
    with {:ok, args} <- required(:user, params, args, type: :string, post: &parse_user/1),
         {:ok, args} <- required(:password, params, args, type: :string),
         {:ok, args} <- required(:type, params, args, type: :string, post: &validate_type/1)
    do
      {:ok, args}
    else
      {:error, {:unknown, :type}} -> {:error, :unknown}
      error -> error
    end
  end


  defp validate_type(@login_type), do: {:ok, @login_type}
  defp validate_type(_), do: {:error, :unknown}


  defp parse_user(user) do
    case UserID.parse(user) do
      :error -> {:error, :bad_type}
      res -> res
    end
  end


end
