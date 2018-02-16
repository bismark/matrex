defmodule MatrexWeb.Controllers.Client.R0.Rooms.Send do
  use MatrexWeb, :authed_controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.Validation.MessageContent, as: MessageContentValidation

  def put(conn, params, access_token) do
    with {:ok, args} <- parse_args(params, conn.body_params),
         {:ok, event_id} <-
           DB.send_event(args.room_id, args.txn_id, args.event_type, args.content, access_token),
         do: {:ok, %{event_id: event_id}}
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
end
