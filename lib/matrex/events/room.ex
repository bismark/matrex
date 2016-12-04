alias Matrex.Events.Room, as: This
defmodule This do

  alias Matrex.Identifier
  alias Matrex.Utils

  @type t :: %This{
    event_id: Identifier.event,
    room_id: Identifier.room,
    sender: Identifier.user,
    origin_server_ts: integer,
    content: struct,
  }

  defstruct [
    :event_id,
    :room_id,
    :sender,
    :origin_server_ts,
    :content,
  ]

  @state_types %{
    #"m.room.aliases" => This.Aliases,
    #"m.room.canonical_alias" => This.CanonicalAlias,
    "m.room.create" => This.Create,
    "m.room.history_visibility" => This.HistoryVisibility,
    "m.room.join_rules" => This.JoinRules,
    "m.room.member" => This.Member,
    "m.room.name" => This.Name,
    #"m.room.power_levels" => This.PowerLevels,
    "m.room.topic" => This.Topic,
    #"m.room.avatar" => This.Avatar,
  }

  @message_types %{
    "m.room.redaction" => This.Redaction,
    "m.room.message" => This.Message,
    "m.room.message.feedback" => This.MessageFeedback,
  }


  def state_content_type(type) do
    Map.get(@state_types, type, This.UnknownState)
  end


  def state_content_factory(type) do
    case Map.fetch(@state_types, type) do
      :error -> This.UnknownState.factory(type)
      {:ok, type} -> &type.from_raw/2
    end
  end


  def create(room_id, sender, content) do
    %This{
      event_id: Identifier.generate(:event),
      room_id: room_id,
      sender: sender,
      origin_server_ts: Utils.timestamp,
      content: content,
    }
  end

end


defmodule This.StateContentBehaviour do
  @callback from_raw(content :: map, state_key :: String.t) :: {:ok, struct} | {:error, atom}
end


defprotocol This.Content do

  @spec type(Content.t) :: String.t
  def type(content)

  @spec is_state?(Content.t) :: boolean
  def is_state?(content)

  @spec state_key(Content.t) :: String.t
  def state_key(content)

  @spec output(Content.t) :: map
  def output(content)

end

defimpl Matrex.Events.Event, for: This do

  alias Matrex.Utils

  def output(this) do
    res = this
      |> Map.from_struct
      |> Map.put(:type, This.Content.type(this.content))
      |> Map.put(:content, This.Content.output(this.content))
      |> Map.put(:age, Utils.age(this.origin_server_ts))

    if This.Content.is_state?(this.content) do
      Map.put(res, :state_key, This.Content.state_key(this.content))
    else
      res
    end
  end

end
