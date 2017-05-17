defmodule Matrex.Controllers.Client.R0.Rooms.Send do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Utils
  alias Matrex.Identifier
  alias Matrex.DB
  alias Matrex.Events.Room, as: RoomEvent
  alias RoomEvent.StateContent
  alias RoomEvent.MessageContent

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


  @spec parse_args(map, map) :: {:ok, map} | {:error, term}

  defp parse_args(%{"state_event_type" => _} = url_params, body) do
    state_key = Map.get(url_params, "state_key", "")
    url_params
      |> Utils.map_move("state_event_type", "event_type")
      |> parse_state_args(state_key, body)
  end

  defp parse_args(url_params, body) do
    acc = %{}
    with {:ok, acc} <- required(:room_id, url_params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:event_type, url_params, acc, type: :string),
         {:ok, acc} <- required(:txn_id, url_params, acc, type: :string),
         {:ok, acc} <- parse_content(body, acc),
    do: {:ok, acc}
  end


  @spec parse_state_args(map, String.t, map) :: {:ok, map} | {:error, term}

  defp parse_state_args(url_params, state_key, body) do
    acc = %{}
    with {:ok, acc} <- required(:room_id, url_params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:event_type, url_params, acc, type: :string),
         {:ok, acc} <- parse_state_content(body, acc, state_key),
         acc = Map.put(acc, :txn_id, nil),
    do: {:ok, acc}
  end


  @spec parse_room_id(String.t) :: {:ok, Identifier.room} | {:error, term}

  defp parse_room_id(room_id) do
    case Identifier.parse(room_id, :room) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end


  @spec parse_state_content(map, map, String.t) :: {:ok, map} | {:error, term}

  defp parse_state_content(raw_content, args, state_key) do
    case StateContent.new(args.event_type, raw_content, state_key) do
      {:ok, content} -> {:ok, Map.put(args, :content, content)}
      error -> error
    end
  end


  defp parse_content(raw_content, args) do
    case MessageContent.new(args.event_type, raw_content) do
      {:ok, content} -> Map.put(args, :content, content)
      error -> error
    end
  end

end
