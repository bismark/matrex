defmodule Matrex.Models.Rooms do

  require Logger

  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Models.Room

  @type t :: %{}

  def new, do: %{}


  @spec create(This.t, map, Identifier.user) :: {Identifier.room, This.t}
  def create(this, args, actor) do
    id = generate_room_id(this)
    room = Room.new(id, args.contents, actor)
    {room.id, Map.put(this, id, room)}
  end


  @spec join_room(This.t, Identifier.room, Identifier.user)
    :: {:ok, This.t} | {:error, atom}
  def join_room(this, room_id, user) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, room} <- Room.join(room, user)
    do
      {:ok, Map.put(this, room_id, room)}
    end
  end


  # Internal Funcs

  @spec fetch_room(This.t, Identifier.room)
    :: {:ok, Room.t} | {:error, :forbidden}
  def fetch_room(this, room_id) do
    case Map.fetch(this, room_id) do
      :error ->
        Logger.error "can't find.."
        {:error, :forbidden}
      res ->
        Logger.error "found"
        res
    end
  end


  @spec generate_room_id(This.t) :: Identifier.room
  defp generate_room_id(this) do
    id = Identifier.generate(:room)
    if Map.has_key?(this, id) do
      generate_room_id(this)
    else
      id
    end
  end


end
