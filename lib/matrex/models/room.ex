defmodule Matrex.Models.Room do
  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Events.Event
  alias Matrex.Events.State
  alias Matrex.Events.Message

  @typep state :: %{State.key() => Event.t()}

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
    create_content = Map.put(create_content, "creator", actor)
    create_event = State.create(id, actor, create_content, "m.room.create")

    # TODO is this correct behaviour?
    join_content = %{"membership" => "join"}
    join_event = State.create(id, actor, join_content, "m.room.member", actor)

    rest_events =
      rest
      |> Enum.map(fn {{type, state_key}, content} ->
        event = State.create(id, actor, content, type, state_key)
        {{type, state_key}, event}
      end)
      |> Enum.into(%{})

    events = Map.values(rest_events) ++ [join_event, create_event]

    state =
      rest_events
      |> Map.put(create_key, create_event)
      |> Map.put(State.key(join_event), join_event)

    %This{id: id, events: events, state: state}
  end

  @spec join(This.t(), Identifier.user()) :: {:ok, This.t()} | {:error, term}
  def join(this, user) do
    case join_rule(this.state) do
      "invite" ->
        {:error, :forbidden}

      "public" ->
        content = %{"membership" => "join"}
        event = State.create(this.id, user, content, "m.room.member", user)
        this = update_state(this, event)
        {:ok, this}
    end
  end

  @spec send_state(This.t(), Identifier.user(), String.t(), String.t(), map) ::
          {:ok, Identifier.event(), This.t()} | {:error, atom}
  def send_state(this, user, event_type, state_key, content) do
    case membership(this.state, user) do
      "join" ->
        event = State.create(this.id, user, content, event_type, state_key)
        {:ok, event.event_id, update_state(this, event)}

      _ ->
        {:error, :forbidden}
    end
  end

  @spec send_event(This.t(), Identifier.user(), String.t(), map) ::
          {:ok, Identifier.event(), This.t()} | {:error, atom}
  def send_event(this, user, event_type, content) do
    case membership(this.state, user) do
      "join" ->
        event = Message.create(this.id, user, content, event_type)
        events = [event | this.events]
        {:ok, event.event_id, %This{this | events: [event | events]}}

      _ ->
        {:error, :forbidden}
    end
  end

  @spec fetch_state(This.t(), String.t(), String.t(), Identifier.user()) ::
          {:ok, State.t(), This.t()} | {:error, atom}
  def fetch_state(this, event_type, state_key, user) do
    case membership(this.state, user) do
      "join" ->
        get_state(this, this.state, {event_type, state_key})

      "leave" ->
        state = get_state_when_left(this, user)
        get_state(this, state, {event_type, state_key})

      _ ->
        {:error, :forbidden}
    end
  end

  @spec fetch_all_state(This.t(), Identifier.user()) ::
          {:ok, [State.t()], This.t()} | {:error, atom}
  def fetch_all_state(this, user) do
    case membership(this.state, user) do
      "join" ->
        {:ok, Map.values(this.state), this}

      "leave" ->
        state = get_state_when_left(this, user)
        {:ok, Map.values(state), this}

      _ ->
        {:error, :forbidden}
    end
  end

  @spec fetch_members(This.t(), String.t() | nil, Identifier.user()) ::
          {:ok, [State.t()], This.t()} | {:error, atom}
  def fetch_members(this, filter, user) do
    case membership(this.state, user) do
      "join" ->
        res = get_members(this.state, filter)
        {:ok, res, this}

      "left" ->
        state = get_state_when_left(this, user)
        res = get_members(state, filter)
        {:ok, res, this}

      _ ->
        {:error, :forbidden}
    end
  end

  # Private Functions

  @spec update_state(This.t(), State.t()) :: This.t()
  defp update_state(this, event) do
    key = State.key(event)

    event =
      case Map.fetch(this.state, key) do
        :error ->
          event

        {:ok, prev_event} ->
          %State{event | prev_state: prev_event}
      end

    events = [event | this.events]
    state = Map.put(this.state, key, event)
    %This{this | events: events, state: state}
  end

  @spec join_rule(state) :: String.t()
  defp join_rule(state) do
    event = Map.fetch!(state, {"m.room.join_rules", ""})
    event.content["join_rule"]
  end

  @spec membership(state, Identifier.user()) :: String.t() | nil
  defp membership(state, user) do
    key = {"m.room.member", user}

    case Map.fetch(state, key) do
      :error -> nil
      {:ok, event} -> event.content["membership"]
    end
  end

  defp get_state(this, state, key) do
    case Map.fetch(state, key) do
      {:ok, content} -> {:ok, content, this}
      :error -> {:error, :not_found}
    end
  end

  defp get_state_when_left(this, user) do
    Enum.reduce_while(this.events, this.state, fn
      %State{type: "m.room.member", state_key: ^user}, state ->
        {:halt, state}

      state_event = %State{prev_state: nil}, state ->
        {:cont, Map.delete(state, State.key(state_event))}

      state_event = %State{}, state ->
        {:cont, Map.put(state, State.key(state_event), state_event.prev_state)}

      _, state ->
        {:cont, state}
    end)
  end

  defp get_members(state, filter) do
    filter_fun =
      case filter do
        nil ->
          fn
            {{"m.room.member", _}, _} -> true
            _ -> false
          end

        filter ->
          fn
            {{"m.room.member", _}, %State{content: %{"membership" => ^filter}}} -> true
            _ -> false
          end
      end

    state
    |> Enum.filter(filter_fun)
    |> Enum.map(&elem(&1, 1))
  end
end
