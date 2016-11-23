defmodule Matrex.Controllers.Client.R0.Room do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Utils
  alias Matrex.DB
  alias Matrex.Events.Room, as: RoomEvent
  alias Matrex.Events.Room.{
    HistoryVisibility,
    JoinRules,
    Create,
    Name,
    Topic,
  }




  def post(conn, _params) do
    access_token = conn.assigns[:access_token]
    with {:ok, args} <- parse_args(conn.body_params),
         {:ok, room_id} <- DB.create_room(args, access_token)
    do
      json(conn, %{room_id: room_id})
    else
      {:error, error} ->
        json_error(conn, error)
    end

  end


  defp parse_args(body) do
    acc = %{}
    with {:ok, acc} <- optional(:creation_content, body, acc, type: :map),
         {:ok, acc} <- optional(:name, body, acc, type: :string),
         {:ok, acc} <- optional(:topic, body, acc, type: :string),
         {:ok, acc} <- optional(:initial_state, body, acc, type: :list, post: &parse_initial_state/1),
         {:ok, acc} <- optional(:preset, body, acc, type: :string, allowed: ["private_chat", "public_chat", "trusted_private_chat"])
         #{:ok, acc} <- optional(:invite, body, acc, type: :list, post: &parse_invite/1),
         #{:ok, acc} <- optional(:visibility, body, acc, type: :string, allowed: ["private", "public"], default: "private"),
         #{:ok, acc} <- optional(:room_alias_name, body, acc, type: :string),
    do
      acc = normalize(acc)
      {:ok, acc}
    end
  end


  defp parse_initial_state(initial_state) do
    Enum.reduce_while(initial_state, {:ok, []}, fn (state, {_,acc}) ->
      event = %{}
      with {:ok, event} <- required(:type, state, event, type: :string),
           {:ok, event} <- required(:content, state, event, type: :map),
           {:ok, event} <- required(:state_key, state, event, type: :string)
      do
        {:cont, {:ok, [event|acc]}}
      else
        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
  end


  def normalize(args) do
    contents = []
      |> gen_create_content(args)
      |> gen_name_content(args)
      |> gen_topic_content(args)
      |> gen_initial_state_content(args)
      |> gen_preset_content(args)

    # TODO handle invites, visibility, alias
    %{contents: contents}
  end


  defp gen_create_content(acc, %{creation_content: %{"m.federate" => federate} = create_content})
   when is_boolean(federate) do
    extra = Map.delete(create_content, "m.federate")
    [Create.new(extra, federate)|acc]
  end
  defp gen_create_content(acc, %{creation_content: create_content}) do
    extra = Map.delete(create_content, "m.federate")
    [Create.new(extra)|acc]
  end
  defp gen_create_content(acc, _) do
    [Create.new(%{})|acc]
  end


  defp gen_name_content(acc, %{name: name}) do
    [Name.new(name)| acc]
  end
  defp gen_name_content(acc, _), do: acc


  defp gen_topic_content(acc, %{topic: topic}) do
    [Topic.new(topic)| acc]
  end
  defp gen_topic_content(acc, _), do: acc


  defp gen_initial_state_content(acc, %{initial_state: initial_state}) do
    Enum.reduce(initial_state, acc, fn (state, acc) ->
      content = RoomEvent.state_content_type(state.type)
      cond do
        content == Topic and Utils.has_struct?(acc, Topic) -> acc
        content == Name and Utils.has_struct?(acc, Name) -> acc
        content == Create -> acc
        true ->
          content_factory = RoomEvent.state_content_factory(state.type)
          case content_factory.(state.content, state.state_key) do
            {:ok, content} -> [content|acc]
            :error -> acc
          end
      end
    end)
  end

  defp gen_initial_state_content(acc, _), do: acc


  defp gen_preset_content(acc, %{preset: preset}) do
    {join_rule, visibility} = case preset do
      "private_chat" -> {:invite, :shared}
      "trusted_private_chat" -> {:invite, :shared}
      "public_chat" -> {:public, :shared}
    end

    acc = if Utils.has_struct?(acc, JoinRules) do
      acc
    else
      [JoinRules.new(join_rule)|acc]
    end

    if Utils.has_struct?(acc, HistoryVisibility) do
      acc
    else
      [HistoryVisibility.new(visibility)|acc]
    end
  end

  defp gen_preset_content(acc, _), do: acc




end
