defmodule Matrex.Controllers.Client.R0.Rooms.Send do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Utils
  alias Matrex.Identifier
  alias Matrex.DB
  alias Matrex.Events.Room, as: RoomEvent

  def put(conn, params) do
    access_token = conn.assigns[:access_token]
    with {:ok, args} <- parse_args(params, conn.body_params),
         {:ok, event_id} <- DB.send_event(args.room_id, args.txn_id, args.content, access_token)
    do
      json(conn, %{event_id: event_id})
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end


  defp parse_args(%{"state_event_type" => _, "state_key" => state_key} = url_params, body) do
    url_params
      |> Utils.map_move("state_event_type", "event_type")
      |> parse_state_args(state_key, body)
  end

  defp parse_args(%{"state_event_type" => _} = url_params, body) do
    url_params
      |> Utils.map_move("state_event_type", "event_type")
      |> parse_state_args("", body)
  end

  defp parse_args(%{"event_type" => _} = url_params, body) do
    acc = %{}
    with {:ok, acc} <- required(:room_id, url_params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:event_type, url_params, acc, type: :string),
         {:ok, acc} <- required(:txn_id, url_params, acc, type: :string),
         {:ok, acc} <- parse_content(body, acc),
    do: {:ok, acc}
  end


  defp parse_state_args(url_params, state_key, body) do
    acc = %{}
    with {:ok, acc} <- required(:room_id, url_params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:event_type, url_params, acc, type: :string),
         {:ok, acc} <- parse_state_content(body, state_key, acc),
         acc = Map.put(acc, :txn_id, nil),
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
         args = Map.put(args, :content, content),
    do: {:ok, args}
  end


  defp parse_state_content(raw_content, state_key, args) do
    content_factory = RoomEvent.state_content_factory(args.event_type)
    with {:ok, content} <- content_factory.(raw_content, state_key),
         args = Map.put(args, :content, content),
    do: {:ok, args}
  end

end
