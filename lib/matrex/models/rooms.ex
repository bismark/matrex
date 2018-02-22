defmodule Matrex.Models.Rooms do
  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Models.Room
  alias Matrex.Events.State

  @type t :: %{Identifier.room() => Room.t()}

  def new, do: %{}

  @spec create(This.t(), integer, map, Identifier.user()) ::
          {Identifier.room(), {integer, This.t()}}
  def create(this, next_event_id, contents, actor) do
    id = generate_room_id(this)
    room = Room.new(id, next_event_id, contents, actor)
    {room.id, Map.put(this, id, room)}
  end

  @spec join_room(This.t(), Identifier.room(), integer, Identifier.user()) ::
          {:ok, This.t()} | {:error, atom}
  def join_room(this, room_id, next_event_id, user) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, room, next_event_id} <- Room.join(room, next_event_id, user) do
      {:ok, {Map.put(this, room_id, room), next_event_id}}
    end
  end

  @spec send_state(
          This.t(),
          Identifier.room(),
          integer,
          Identifier.user(),
          String.t(),
          String.t(),
          map
        ) :: {:ok, Identifier.event(), This.t()} | {:error, atom}
  def send_state(this, room_id, next_event_id, user, event_type, state_key, content) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, event_id, room, next_event_id} <-
           Room.send_state(room, next_event_id, user, event_type, state_key, content) do
      {:ok, event_id, {Map.put(this, room_id, room), next_event_id}}
    end
  end

  @spec send_event(This.t(), Identifier.room(), integer, Identifier.user(), String.t(), map) ::
          {:ok, Identifier.event(), This.t()} | {:error, atom}
  def send_event(this, room_id, next_event_id, user, event_type, content) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, event_id, room, next_event_id} <-
           Room.send_event(room, next_event_id, user, event_type, content) do
      {:ok, event_id, {Map.put(this, room_id, room), next_event_id}}
    end
  end

  @spec fetch_state(
          This.t(),
          Identifier.room(),
          String.t(),
          String.t(),
          Identifier.user()
        ) :: {:ok, State.t(), This.t()} | {:error, atom}
  def fetch_state(this, room_id, event_type, state_key, user) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, content, room} <- Room.fetch_state(room, event_type, state_key, user) do
      {:ok, content, Map.put(this, room_id, room)}
    end
  end

  @spec fetch_all_state(This.t(), Identifier.room(), Identifier.user()) ::
          {:ok, [State.t()], This.t()} | {:error, atom}
  def fetch_all_state(this, room_id, user) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, state, room} <- Room.fetch_all_state(room, user) do
      {:ok, state, Map.put(this, room_id, room)}
    end
  end

  @spec fetch_members(This.t(), Identifier.room(), String.t() | nil, Identifier.user()) ::
          {:ok, [State.t()], This.t()} | {:error, atom}
  def fetch_members(this, room_id, filter, user) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, state, room} <- Room.fetch_members(room, filter, user),
         do: {:ok, state, Map.put(this, room_id, room)}
  end

  # Internal Funcs

  @spec fetch_room(This.t(), Identifier.room()) :: {:ok, Room.t()} | {:error, :forbidden}
  def fetch_room(this, room_id) do
    case Map.fetch(this, room_id) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end

  @spec generate_room_id(This.t()) :: Identifier.room()
  defp generate_room_id(this) do
    id = Identifier.generate(:room)

    if Map.has_key?(this, id) do
      generate_room_id(this)
    else
      id
    end
  end
end
