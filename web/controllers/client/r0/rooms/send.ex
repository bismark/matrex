defmodule Matrex.Controllers.Client.R0.Rooms.Send do
  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Identifier
  alias Matrex.DB
  alias Matrex.Validation.MessageContent, as: MessageContentValidation

  def put(conn, params) do
    access_token = conn.assigns[:access_token]

    with {:ok, args} <- parse_args(params, conn.body_params),
         {:ok, event_id} <-
           DB.send_event(args.room_id, args.txn_id, args.event_type, args.content, access_token) do
      json(conn, %{event_id: event_id})
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end

  defp parse_args(url_params, body) do
    acc = %{}

    with {:ok, acc} <- required(:room_id, url_params, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- required(:event_type, url_params, acc, type: :string),
         {:ok, acc} <- required(:txn_id, url_params, acc, type: :string),
         {:ok, content} <- MessageContentValidation.parse_content(acc.event_type, body),
         acc = Map.put(acc, :content, content),
         do: {:ok, acc}
  end

  @spec parse_room_id(String.t()) :: {:ok, Identifier.room()} | {:error, term}

  defp parse_room_id(room_id) do
    case Identifier.parse(room_id, :room) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end
end
