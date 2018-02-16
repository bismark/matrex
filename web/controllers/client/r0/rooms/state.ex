defmodule Matrex.Controllers.Client.R0.Rooms.State do
  use Matrex.Web, :authed_controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.Validation.StateContent, as: StateContentValidation
  alias Matrex.Events.Event

  def get_all(_conn, params, access_token) do
    with {:ok, args} <- parse_get_all_args(params),
         {:ok, state} <- DB.fetch_all_state(args.room_id, access_token),
         do: {:ok, Enum.map(state, &Event.output/1)}
  end

  def get(_conn, params, access_token) do
    with {:ok, args} <- parse_get_args(params),
         {:ok, state} <-
           DB.fetch_state(args.room_id, args.event_type, args.state_key, access_token),
         do: {:ok, Event.output(state)}
  end

  def put(conn, params, access_token) do
    with {:ok, args} <- parse_put_args(params, conn.body_params),
         {:ok, event_id} <-
           DB.send_state(
             args.room_id,
             args.state_event_type,
             args.state_key,
             args.content,
             access_token
           ),
         do: {:ok, %{event_id: event_id}}
  end

  defp parse_get_all_args(params) do
    acc = %{}

    with {:ok, acc} <- required(:room_id, params, acc, type: :string, post: &parse_room_id/1),
         do: {:ok, acc}
  end

  defp parse_get_args(params) do
    acc = %{}

    with {:ok, acc} <- required(:room_id, params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:event_type, params, acc, type: :string),
         {:ok, acc} <- optional(:state_key, params, acc, type: :string, default: ""),
         do: {:ok, acc}
  end

  @spec parse_put_args(map, map) :: {:ok, map} | {:error, term}

  defp parse_put_args(url_params, body) do
    acc = %{}

    with {:ok, acc} <- required(:room_id, url_params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:state_event_type, url_params, acc, type: :string),
         {:ok, acc} <- optional(:state_key, url_params, acc, type: :string, default: ""),
         {:ok, content} <-
           StateContentValidation.parse_content(acc.state_event_type, body, acc.state_key),
         acc = Map.put(acc, :content, content),
         do: {:ok, acc}
  end
end
