defmodule Matrex.Models.Room do

  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Events.Event
  alias Matrex.Events.Room, as: RoomEvent
  alias Matrex.Events.Room.{
    Create,
    JoinRules,
    Member,
  }


  @type t :: %This{
    id: Identifier.t,
    state: map,
    events: [Event.t],
  }

  @enforce_keys [:id]

  defstruct [
    :id,
    :state,
    events: [],
  ]


  @spec new(Identifier.room, [RoomEvent.Content.t], Identifier.user)
    :: This.t
  def new(id, contents, actor) do
    # TODO Let's default to public for now...
    has_join_rules? = Enum.any?(contents, fn
       (%JoinRules{}) -> true
       (_) -> false
    end)
    contents = case has_join_rules? do
      false -> [JoinRules.new(:public)|contents]
      true -> contents
    end

    events = Enum.map(contents, fn
       %Create{} = content ->
         content = Create.set_creator(content, actor)
         RoomEvent.create(id, actor, content)
       content ->
         RoomEvent.create(id, actor, content)
    end)

    state = %{joined_members: MapSet.new}

    update_state(%This{id: id, events: events, state: state}, events)
  end


  @spec join(This.t, Identifier.user) :: {:ok, This.t} | {:error, atom}
  def join(this, user) do
    case this.state.join_rule do
      :invite -> {:error, :forbidden}
      :public ->
        content = Member.new(user, :join)
        event = RoomEvent.create(this.id, user, content)
        this = %This{this | events: [event|this.events]}
        {:ok, update_state(this, [event])}
    end
  end


  @spec send_event(This.t, Identifier.user, RoomEvent.Content.t)
    :: {:ok, Identifier.event, This.t} | {:error, atom}
  def send_event(this, user, content) do
    case MapSet.member?(this.state.joined_members, user) do
      false -> {:error, :forbidden}
      true ->
        event = RoomEvent.create(this.id, user, content)
        this = %This{this | events: [event|this.events]}
        {:ok, event.event_id, this}
    end
  end


  # Internal Funcs

  @spec update_state(This.t, [RoomEvent.t]) :: This.t
  defp update_state(this, []), do: this
  defp update_state(this, [%RoomEvent{content: %JoinRules{join_rule: rule}}|rest]) do
    this = %This{this | state: Map.put(this.state, :join_rule, rule)}
    update_state(this, rest)
  end
  defp update_state(this, [%RoomEvent{content: %Member{} = content}|rest]) do
    user = content.state_key
    this = case content.membership do
      :join ->
        joined_members = MapSet.put(this.state.joined_members, user)
        state = Map.put(this.state, :joined_members, joined_members)
        %This{this | state: state}
      :leave ->
        joined_members = MapSet.delete(this.state.joined_members, user)
        state = Map.put(this.state, :joined_members, joined_members)
        %This{this | state: state}
    end
    update_state(this, rest)
  end
  defp update_state(this, [_|rest]) do
    update_state(this, rest)
  end


end
