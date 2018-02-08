defmodule Matrex.Models.Room do
  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Events.Event
  alias Matrex.Events.Room, as: RoomEvent
  alias Matrex.Events.Room.StateContent

  @typep state :: %{StateContent.key() => Event.t()}

  @type t :: %This{
          id: Identifier.room(),
          state: state,
          events: [Event.t()]
        }

  @enforce_keys [:id]

  defstruct [
    :id,
    :state,
    :events
  ]

  @spec new(Identifier.room(), map, Identifier.user()) :: This.t()
  def new(id, contents, actor) do
    create_key = {"m.room.create", ""}
    {create_content, rest} = Map.pop(contents, create_key)
    create_content = StateContent.set_content(create_content, "creator", actor)
    create_event = RoomEvent.create(id, actor, create_content)

    # TODO is this correct behaviour?
    join_content = %{"membership" => "join"}
    {:ok, join_content} = StateContent.new("m.room.member", join_content, actor)
    join_event = RoomEvent.create(id, actor, join_content)

    rest_events =
      rest
      |> Enum.map(fn {key, content} ->
        event = RoomEvent.create(id, actor, content)
        {key, event}
      end)
      |> Enum.into(%{})

    events = Map.values(rest_events) ++ [join_event, create_event]

    state =
      rest_events
      |> Map.put(create_key, create_event)
      |> Map.put(StateContent.key(join_content), join_event)

    %This{id: id, events: events, state: state}
  end

  @spec join(This.t(), Identifier.user()) :: {:ok, This.t()} | {:error, term}
  def join(this, user) do
    case join_rule(this.state) do
      "invite" ->
        {:error, :forbidden}

      "public" ->
        content = %{"membership" => "join"}
        {:ok, content} = StateContent.new("m.room.member", content, user)
        this = update_state(this, user, content)
        {:ok, this}
    end
  end

  @spec send_event(This.t(), Identifier.user(), RoomEvent.content()) ::
          {:ok, Identifier.event(), This.t()} | {:error, atom}
  def send_event(this, user, content) do
    case membership(this.state, user) do
      "join" ->
        event = RoomEvent.create(this.id, user, content)
        events = [event | this.events]
        state = Map.put(this.state, StateContent.key(content), content)
        {:ok, event.event_id, %This{this | events: events, state: state}}

      _ ->
        {:error, :forbidden}
    end
  end

  @spec update_state(This.t(), Identifier.user(), StateContent.t() | nil) :: This.t()
  defp update_state(this, actor, content) do
    key = StateContent.key(content)

    event =
      case Map.fetch(this.state, key) do
        :error ->
          RoomEvent.create(this.id, actor, content)

        {:ok, prev_event} ->
          prev_content = prev_event.content.content
          content = %StateContent{content | prev_content: prev_content}
          RoomEvent.create(this.id, actor, content)
      end

    events = [event | this.events]
    state = Map.put(this.state, key, event)
    %This{this | events: events, state: state}
  end

  @spec join_rule(state) :: String.t()
  defp join_rule(state) do
    event = Map.fetch!(state, {"m.room.join_rules", ""})
    event.content.content["join_rule"]
  end

  defp membership(state, user) do
    key = {"m.room.member", user}

    case Map.fetch(state, key) do
      :error -> nil
      {:ok, event} -> event.content["membership"]
    end
  end
end
