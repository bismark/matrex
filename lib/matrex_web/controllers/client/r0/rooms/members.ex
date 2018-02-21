defmodule MatrexWeb.Controllers.Client.R0.Rooms.Members do
  use MatrexWeb, :authed_controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.Events.Event
  alias Matrex.Events.State
  alias Matrex.Identifier

  def get(_conn, params, access_token) do
    with {:ok, args} <- parse_args(params),
         {:ok, members} <- DB.fetch_members(args.room_id, access_token),
         do: {:ok, %{chunk: Enum.map(members, &Event.output/1)}}
  end

  def get_joined(_conn, params, access_token) do
    with {:ok, args} <- parse_args(params),
         {:ok, members} <- DB.fetch_members(args.room_id, access_token, "join"),
         res = format_joined(members),
         do: {:ok, %{joined: res}}
  end

  defp parse_args(params) do
    acc = %{}

    with {:ok, acc} <- required(:room_id, params, acc, type: :string, post: &parse_room_id/1),
         do: {:ok, acc}
  end

  defp format_joined(members) do
    Enum.reduce(members, %{}, fn %State{state_key: user}, acc ->
      Map.put(acc, Identifier.fqid(user), %{})
    end)
  end
end
