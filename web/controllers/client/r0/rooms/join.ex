defmodule Matrex.Controllers.Client.R0.Rooms.Join do
  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Identifier
  alias Matrex.DB

  def post(conn, params) do
    access_token = conn.assigns[:access_token]

    with {:ok, args} <- parse_args(params),
         {:ok, room_id} <- DB.join_room(args.room_id, access_token) do
      json(conn, %{room_id: room_id})
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end

  @spec parse_args(map) :: {:ok, map} | {:error, term}

  defp parse_args(args) do
    acc = %{}

    with {:ok, acc} <- required(:room_id, args, acc, type: :string, post: &parse_room_id/1),
         do: {:ok, acc}
  end

  @spec parse_room_id(String.t()) :: {:ok, Identifier.room()} | {:error, :forbidden}
  defp parse_room_id(room_id) do
    case Identifier.parse(room_id, :room) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end
end
