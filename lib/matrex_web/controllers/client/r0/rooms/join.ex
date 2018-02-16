defmodule MatrexWeb.Controllers.Client.R0.Rooms.Join do
  use MatrexWeb, :authed_controller

  import Matrex.Validation

  alias Matrex.DB

  def post(_conn, params, access_token) do
    with {:ok, args} <- parse_args(params),
         {:ok, room_id} <- DB.join_room(args.room_id, access_token),
         do: {:ok, %{room_id: room_id}}
  end

  @spec parse_args(map) :: {:ok, map} | {:error, term}

  defp parse_args(args) do
    acc = %{}

    with {:ok, acc} <- required(:room_id, args, acc, type: :string, post: &parse_room_id/1),
         do: {:ok, acc}
  end
end
