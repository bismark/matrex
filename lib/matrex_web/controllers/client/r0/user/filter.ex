defmodule MatrexWeb.Controllers.Client.R0.User.Filter do
  use MatrexWeb, :authed_controller

  import Matrex.Validation

  alias Matrex.DB
  alias Matrex.Identifier
  alias Matrex.Models.UserFilter

  def post(_conn, params, access_token) do
    with {:ok, args} <- parse_post_args(params),
         {:ok, filter_id} <- DB.create_filter(args.filter, access_token),
         do: {:ok, %{filter_id: filter_id}}
  end

  def get(_conn, params, access_token) do
    with {:ok, args} <- parse_get_args(params),
         {:ok, filter} <- DB.get_filter(args.filter_id, access_token),
         do: {:ok, %{filter: filter}}
  end

  defp parse_get_args(args) do
    acc = %{}
    with {:ok, acc} <- required(:filter_id, args, acc, type: :string), do: {:ok, acc}
  end

  defp parse_post_args(args) do
    acc = %{}

    with {:ok, acc} <- required(:user_id, args, acc, type: :string, post: &parse_room_id/1),
         {:ok, acc} <- optional(:event_fields, args, acc, type: :list, post: &parse_strings/1),
         {:ok, acc} <- optional(:presence, args, acc, type: :map, post: &parse_filter/1),
         {:ok, acc} <- optional(:account_data, args, acc, type: :map, post: &parse_filter/1),
         {:ok, acc} <- optional(:room, args, acc, type: :map, post: &parse_room_filter/1) do
      {user_id, filter} = Map.pop(acc, :user_id)
      {:ok, %{user_id: user_id, filter: struct(UserFilter, filter)}}
    end
  end

  defp parse_filter(filter) do
    with {:ok, acc} <- parse_filter_fields(filter), do: {:ok, struct(UserFilter.Filter, acc)}
  end

  defp parse_room_filter(filter) do
    acc = %{}

    with {:ok, acc} <-
           optional(:not_rooms, filter, acc, type: :list, post: &parse_identifiers(&1, :room)),
         {:ok, acc} <-
           optional(:rooms, filter, acc, type: :list, post: &parse_identifiers(&1, :room)),
         {:ok, acc} <-
           optional(:ephemeral, filter, acc, type: :map, post: &parse_room_event_filter/1),
         {:ok, acc} <- optional(:include_leave, filter, acc, type: :boolean, default: false),
         {:ok, acc} <- optional(:state, filter, acc, type: :map, post: &parse_room_event_filter/1),
         {:ok, acc} <-
           optional(:timeline, filter, acc, type: :map, post: &parse_room_event_filter/1),
         {:ok, acc} <-
           optional(:account_data, filter, acc, type: :map, post: &parse_room_event_filter/1),
         do: {:ok, struct(UserFilter.RoomFilter, acc)}
  end

  defp parse_room_event_filter(filter) do
    with {:ok, acc} <- parse_filter_fields(filter),
         {:ok, acc} <-
           optional(:not_rooms, filter, acc, type: :list, post: &parse_identifiers(&1, :room)),
         {:ok, acc} <-
           optional(:rooms, filter, acc, type: :list, post: &parse_identifiers(&1, :room)),
         {:ok, acc} <- optional(:contains_url, filter, acc, type: :boolean),
         do: {:ok, struct(UserFilter.RoomFilter.EventFilter, acc)}
  end

  defp parse_filter_fields(filter) do
    acc = %{}

    with {:ok, acc} <- optional(:limit, filter, acc, type: :integer),
         {:ok, acc} <-
           optional(:not_senders, filter, acc, type: :list, post: &parse_identifiers(&1, :user)),
         {:ok, acc} <- optional(:not_types, filter, acc, type: :list, post: &parse_strings/1),
         {:ok, acc} <-
           optional(:senders, filter, acc, type: :list, post: &parse_identifiers(&1, :user)),
         {:ok, acc} <- optional(:types, filter, acc, type: :list, post: &parse_strings/1),
         do: {:ok, acc}
  end

  defp parse_strings(strings) do
    res =
      Enum.all?(strings, fn
        field when is_binary(field) -> true
        _ -> false
      end)

    if res, do: {:ok, strings}, else: {:error, :bad_value}
  end

  defp parse_identifiers(ids, type) do
    Enum.reduce_while(ids, {:ok, []}, fn id, {:ok, acc} ->
      case Identifier.parse(id, type) do
        {:ok, id} -> {:cont, {:ok, [id | acc]}}
        :error -> {:halt, {:error, :bad_value}}
      end
    end)
  end
end
