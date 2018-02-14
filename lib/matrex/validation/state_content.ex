defmodule Matrex.Validation.StateContent do
  import Matrex.Validation

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
  @spec parse_content(String.t(), map, String.t()) :: {:ok, map} | {:error, term}

  def parse_content(type, content, state_key \\ "")

  def parse_content("m.room.create", content, "") do
    options = [type: :boolean, default: true]
    optional("m.federate", content, %{}, options)
  end

  def parse_content("m.room.create", _content, _) do
    {:error, :bad_value}
  end

  def parse_content("m.room.history_visibility", content, "") do
    options = [type: :string, allowed: @allowed_history_visibility]
    required("history_visibility", content, %{}, options)
  end

  def parse_content("m.room.history_visibility", _content, _) do
    {:error, :bad_value}
  end

  def parse_content("m.room.join_rules", content, "") do
    options = [type: :string, allowed: @allowed_join_rules]
    required("join_rule", content, %{}, options)
  end

  def parse_content("m.room.join_rules", _content, _) do
    {:error, :bad_value}
  end

  def parse_content("m.room.member", content, key) when is_binary(key) and byte_size(key) > 0 do
    options = [type: :string, allowed: @allowed_membership]
    required("membership", content, %{}, options)
  end

  def parse_content("m.room.member", _content, _) do
    {:error, :bad_value}
  end

  def parse_content("m.room.name", content, "") do
    options = [type: :string]
    required("name", content, %{}, options)
  end

  def parse_content("m.room.name", _content, _) do
    {:error, :bad_value}
  end

  def parse_content("m.room.topic", content, "") do
    options = [type: :string]
    required("topic", content, %{}, options)
  end

  def parse_content("m.room.topic", _content, _) do
    {:error, :bad_value}
  end

  def parse_content(_, content, _), do: {:ok, content}
end
