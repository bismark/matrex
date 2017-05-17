defmodule Matrex.Errors do

  import Phoenix.Controller, only: [json: 2]
  alias Plug.Conn

  @typep error :: atom | {atom, any}

  @spec json_error(Conn.t, error) :: Conn.t
  def json_error(conn, error) do
    conn
      |> Conn.put_status(status_code(error))
      |> json(%{
        errcode: error(error),
        error: message(error),
      })
  end


  @spec error(error) :: String.t
  defp error(:user_in_user), do: "M_USER_IN_USE"
  defp error(:invalid_username), do: "M_INVALID_USERNAME"
  defp error({:missing_arg, _}), do: "M_BAD_JSON"
  defp error({:bad_type, _}), do: "M_BAD_JSON"
  defp error(:unknown), do: "M_UNKNOWN"
  defp error(:forbidden), do: "M_FORBIDDEN"
  defp error(:missing_token), do: "M_MISSING_TOKEN"
  defp error(:unknown_token), do: "M_UNKNOWN_TOKEN"
  defp error(_), do: "M_UNRECOGNIZED"

  @spec status_code(error) :: integer
  defp status_code(:user_in_use), do: 400
  defp status_code(:invalid_username), do: 400
  defp status_code({:missing_arg,_}), do: 400
  defp status_code({:bad_type,_}), do: 400
  defp status_code(:unknown), do: 400
  defp status_code(:forbidden), do: 403
  defp status_code(:missing_token), do: 401
  defp status_code(:unknown_token), do: 401
  defp status_code(_), do: 500

  @spec message(error) :: String.t
  defp message(:user_in_user), do: "User ID already taken"
  defp message(:invalid_username), do: "User ID is invalid"
  defp message({:missing_arg, key}), do: "Missing required key #{key}"
  defp message({:bad_type, key}), do: "Bad type for key #{key}"
  defp message(:unknown), do: "Bad login type"
  defp message(:forbidden), do: "Forbidden"
  defp message(:missing_token), do: "Access token missing"
  defp message(:unknown_token), do: "Unknown access token"
  defp message(_), do: "Unknown Error"



end
