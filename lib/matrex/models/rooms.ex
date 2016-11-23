defmodule Matrex.Models.Rooms do

  @type t :: %{}

  alias Matrex.Identifier
  alias Matrex.Models.Room


  def new, do: %{}


  def create(this, args, actor) do
    id = generate_room_id(this)
    room = Room.new(id, args.contents, actor)
    {room, Map.put(this, id, room)}
  end


  defp generate_room_id(this) do
    id = Identifier.generate(:room)
    if Map.has_key?(this, id) do
      generate_room_id(this)
    else
      id
    end
  end


end
