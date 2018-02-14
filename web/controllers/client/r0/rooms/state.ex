defmodule Matrex.Controllers.Client.R0.Rooms.State do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Utils
  alias Matrex.Identifier
  alias Matrex.DB
  alias Matrex.Validation.StateContent, as: StateContentValidation

  def put(conn, params) do
    access_token = conn.assigns[:access_token]
    with {:ok, args} <- parse_args(params, conn.body_params),
         {:ok, event_id} <- DB.send_state(args.room_id, args.state_event_type, args.state_key, args.content, access_token)
    do
      json(conn, %{event_id: event_id})
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end

  @spec parse_args(map, map) :: {:ok, map} | {:error, term}

  defp parse_args(url_params, body) do
    acc = %{}
    with {:ok, acc} <- required(:room_id, url_params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:state_event_type, url_params, acc, type: :string),
         {:ok, acc} <- optional(:state_key, url_params, acc, type: :string, default: ""),
         {:ok, content} <- StateContentValidation.parse_content(acc.state_event_type, body, acc.state_key),
         acc = Map.put(acc, :content, content),
    do: {:ok, acc}
  end

  @spec parse_room_id(String.t) :: {:ok, Identifier.room} | {:error, term}

  defp parse_room_id(room_id) do
    case Identifier.parse(room_id, :room) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end

end

