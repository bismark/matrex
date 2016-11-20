defmodule Matrex.Controllers.Client.R0.Register do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.UserID


  def post(conn, _params) do
    with {:ok, args} <- parse_args(conn.body_params),
         {:ok, tokens, username} <- DB.register(args)
    do
      {access_token, refresh_token} = tokens
      hostname = Application.get_env(:matrex, :hostname)
      resp = %{
        user_id: UserID.fquid(username, hostname),
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
    with {:ok, args} <- optional(:username, params, args, type: :string, post: &check_username/1),
         {:ok, args} <- required(:password, params, args, type: :string),
         {:ok, args} <- required(:auth, params, args, type: :map, post: &process_auth/1)
    do
      {:ok, args}
    end
  end


  defp process_auth(auth) do
    args = %{}
    with {:ok, args} <- required(:type, auth, args, type: :string) do
      {:ok, args}
    end
  end


  defp check_username(username) do
    hostname = Application.get_env(:matrex, :hostname)
    with true <- UserID.valid_localpart?(username),
         true <- UserID.valid_fquid?(username, hostname)
    do
      {:ok, username}
    else
      false ->
        {:error, :invalid_username}
    end
  end

end
