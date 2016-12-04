defmodule Matrex.Controllers.Client.R0.Rooms.Send do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Identifier
  alias Matrex.DB
  alias Matrex.Events.Room, as: RoomEvent

  def put(conn, _params) do
    access_token = conn.assigns[:access_token]
    with {:ok, args} <- parse_args(conn),
         {:ok, event_id} <- DB.send_event(args.room_id, args.txn_id, args.content, access_token)
    do
      json(conn, %{event_id: event_id})
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end


  defp parse_args(conn) do
    args = conn.params
    acc = %{}
    with {:ok, acc} <- required(:room_id, args, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:event_type, args, acc, type: :string),
         {:ok, acc} <- required(:txn_id, args, acc, type: :string),
         {:ok, acc} <- parse_content(conn.body_params, acc),
    do: {:ok, acc}
  end


  defp parse_room_id(room_id) do
    case Identifier.parse(room_id, :room) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end


  defp parse_content(raw_content, args) do
    content_factory = RoomEvent.content_factory(args.event_type)
    with {:ok, content} <- content_factory.(raw_content),
    do: {:ok, Map.put(args, :content, content)}
  end


end
