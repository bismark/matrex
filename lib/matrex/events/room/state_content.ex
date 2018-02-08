defmodule Matrex.Events.Room.StateContent do
  import Matrex.Validation

  alias __MODULE__, as: This

  @type key :: {String.t(), String.t()}

  @type t :: %This{
          content: map,
          prev_content: nil | map,
          state_key: any,
          type: String.t()
        }

  defstruct [
    :content,
    :prev_content,
    :state_key,
    :type
  ]

  @spec new(String.t(), map, any) :: {:ok, This.t()} | {:error, term}

  def new(type, content, state_key \\ "") do
    with {:ok, parsed} <- parse_content(type, content),
         content = Map.merge(content, parsed),
         do: {:ok, %This{type: type, content: content, state_key: state_key}}
  end

  @spec key(This.t()) :: key
  def key(this), do: {this.type, this.state_key}

  @spec set_content(This.t(), String.t(), any) :: This.t()

  def set_content(this, key, value) do
    content = Map.put(this.content, key, value)
    %This{this | content: content}
  end

  @allowed_history_visibility [
    "invited",
    "joined",
    "shared",
    "world_readable"
  ]

  @allowed_join_rules [
    "public",
    "invite"
  ]

  @allowed_membership [
    "invite",
    "join",
    "leave",
    "ban"
  ]

  @spec parse_content(String.t(), map) :: {:ok, map} | {:error, term}

  defp parse_content("m.room.create", content) do
    options = [type: :boolean, default: true]
    optional("m.federate", content, %{}, options)
  end

  defp parse_content("m.room.history_visibility", content) do
    options = [type: :string, allowed: @allowed_history_visibility]
    required("history_visibility", content, %{}, options)
  end

  defp parse_content("m.room.join_rules", content) do
    options = [type: :string, allowed: @allowed_join_rules]
    required("join_rule", content, %{}, options)
  end

  defp parse_content("m.room.member", content) do
    options = [type: :string, allowed: @allowed_membership]
    required("membership", content, %{}, options)
  end

  defp parse_content("m.room.name", content) do
    options = [type: :string]
    required("name", content, %{}, options)
  end

  defp parse_content("m.room.topic", content) do
    options = [type: :string]
    required("topic", content, %{}, options)
  end

  defp parse_content(_, content), do: {:ok, content}
end
