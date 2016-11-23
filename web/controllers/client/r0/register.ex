defmodule Matrex.Controllers.Client.R0.Register do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.Identifier
  alias Matrex.Utils


  def post(conn, _params) do
    with {:ok, args} <- parse_args(conn.body_params),
         {:ok, tokens, user_id} <- DB.register(args)
    do
      {access_token, refresh_token} = tokens
      resp = %{
        user_id: user_id,
        access_token: access_token,
        refesh_token: refresh_token,
        home_server: user_id.hostname
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
      args = Utils.map_move(args, :username, :user_id)
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
    user_id = Identifier.new(:user, username, Matrex.hostname)
    case Identifier.valid?(user_id) do
      true -> {:ok, user_id}
      false -> {:error, :invalid_username}
    end
  end

end
